# coding: utf-8
class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  def req_search_api(condition, page)
    search_word    = ''
    keyword        = condition['keyword']
    negative_match = condition['negative_match']

    keyword.split.each do |word|
      search_word << "#{word} "
    end
    negative_match.split.each do |word|
      search_word << "-#{word} "
    end

    retry_count = 0
    begin
      res = Amazon::Ecs.item_search(
        search_word,
        :search_index   => condition['category'],
        :response_group => 'Large',
        :country        => 'jp',
        :item_page      => page
      )
    rescue
      retry_count += 1
      if retry_count < 5
        sleep(5)
        retry
      else
        return false
      end
    end

    ret_items = []
    res.items.each do |item|
      insert_item = _format_item(item)
      next unless _validate_item(insert_item, condition)
      ret_items.push(insert_item)
    end

    # 色違いの商品の取得
    parent_asins = []
    res.items.each do |item|
      parent_asins.push(item.get('ParentASIN')) if item.get('ParentASIN')
    end
    ret_items.concat(_get_variation_items(parent_asins, condition))

    # 重複を削除する
    ret_items.uniq! {|item| item['asin']}

    return ret_items
  end

  # asinsの配列から商品情報を取得する
  # codeを生成するために、label_idを渡してもらう必要がある
  def req_lookup_api(asins, label_id)
    ret_items = []

    # 10件ずつしか商品データを取得できない。Amazon APIの仕様。
    asins.each_slice(10).to_a.each do |ele|
      retry_count = 0
      begin
        res = Amazon::Ecs.item_lookup(ele.join(','),
                                      :response_group => 'Large',
                                      :country        => 'jp'
                                     )
      rescue
        retry_count += 1
        if retry_count < 5
          sleep(5)
          retry
        else
          return false
        end
      end

      res.items.each do |item|
        insert_item = _format_item(item)
        # codeを生成する
        insert_item['code'] = generate_code(insert_item['asin'], label_id)
        ret_items.push(insert_item)
      end
    end

    return ret_items
  end

  # parent_asinsの配列から色違いの商品情報を取得する。(配列を返す)
  # parent_asinsのものは削除
  def _get_variation_items(parent_asins, condition)
    retry_count = 0
    begin
      res = Amazon::Ecs.item_lookup(parent_asins.join(','),
                                    :response_group => 'Variations',
                                    :country        => 'jp'
                                   )
    rescue
      retry_count += 1
      if retry_count < 5
        sleep(5)
        retry
      else
        return false
      end
    end

    variation_items = []
    res.items.each do |item|
      insert_item = _format_item(item)
      next unless _validate_item(insert_item, condition)
      variation_items.push(insert_item)
    end

    # parent_asinsのものは削除
    variation_items.delete_if { |item| parent_asins.include?(item['asin']) }

    return variation_items
  end

  def _validate_item(item, condition)
    # プライム指定でフィルタリング
    return false unless _check_condition_of_is_prime(item, condition['is_prime'].to_s)
    # 在庫状況でフィルタリング
    return false unless _is_availability(item)
    # 金額が取れていなければ、取得しない
    return false if item['price'].to_s == '0'
    # 禁止ワードがあれば、取得しない
    prohibited_words = ProhibitedWord.where(user_id: current_user.id)
    prohibited_words.each do |prohibited_word|
      return false if "#{item['title']} #{item['headline']} #{item['features'].join(' ')}" =~ /#{prohibited_word.name}/
    end

    return true
  end

  def _format_item(item)
    item_attributes = item.get_element('ItemAttributes')
    main_img_url    = item.get('LargeImage/URL')
    sub_img_urls    = item.get_array('ImageSets/ImageSet/LargeImage/URL')
    # img_urlsにはmain_img_urlも含まれるので消す
    sub_img_urls.delete(main_img_url) if sub_img_urls

    offer_listing = item.get_element('Offers/Offer/OfferListing')
    is_prime = offer_listing ? offer_listing.get('IsEligibleForPrime') : 0
    availability = offer_listing ? offer_listing.get('Availability') : 0
    price = offer_listing ? offer_listing.get('Price/Amount') : 0

    insert_item = {
      'asin'         => item.get('ASIN'),
      'jan'          => item_attributes ? item_attributes.get('EAN') : '',
      'title'        => item_attributes ? item_attributes.get('Title') : '',
      'url'          => item.get('DetailPageURL'),
      'price'        => price,
      'headline'     => item_attributes ? item_attributes.get('Brand') : '',
      'features'     => item_attributes ? item_attributes.get_array('Feature') : '',
      'is_prime'     => is_prime,
      'availability' => availability,
      'main_img_url' => main_img_url,
      'sub_img_urls' => sub_img_urls
    }

    return insert_item
  end

  def _check_condition_of_is_prime(item, is_prime)
    if is_prime == '1' then
      return true  if item['is_prime'].to_s == '1'
    else
      return true
    end
    return false
  end

  def _is_availability(item)
    return true if ["在庫あり。","通常1～2営業日以内に発送","通常1～3営業日以内に発送","通常2～3営業日以内に発送"].include?(item['availability'])
    return false
  end

  def create_csv_str(items, csv_option)
    csv_header = %w/ path name code sub-code original-price price sale-price options headline caption abstract explanation additional1 additional2 additional3 /
    # テンプレートファイルを開く
    caption_erb = Rails.root.join('app/views/template/caption.html.erb').read

    csv_str = CSV.generate do |csv|
      # header の追加
      csv << csv_header
      # body の追加
      items.each do |item|
        csv_body = {}

        csv_body['path']        = csv_option['path'] if csv_option['path']
        csv_body['name']        = item['title'].byteslice(0,150).scrub('') # nameカラムは半角150文字以内
        csv_body['code']        = item['code']
        csv_body['headline']    = item['headline']
        csv_body['caption']     = ERB.new(caption_erb, nil, '-').result(binding)
        csv_body['explanation'] = csv_option['explanation'] if csv_option['explanation']

        # 金額調整
        if (csv_option['price_option_value'])  then
          if (csv_option['price_option_unit'] == 'yen') then
            csv_body['price'] = item['price'] + csv_option['price_option_value']
          elsif (csv_option['price_option_unit'] == 'per') then
            csv_body['price'] = item['price'] * csv_option['price_option_value']
          end
        end
        csv_body['price'] = csv_body['price'].to_i

        csv << csv_body.values_at(*csv_header)
      end
    end

    return csv_str
  end

  def create_out_stock_csv_str(codes)
    csv_header = %w/ code /

    csv_str = CSV.generate do |csv|
      # header の追加
      csv << csv_header
      # body の追加
      codes.each do |code|
        csv_body = {}

        csv_body['code'] = code

        csv << csv_body.values_at(*csv_header)
      end
    end

    return csv_str
  end

  def generate_code(asin, label_id)
    code = label_id.to_s + Digest::MD5.hexdigest(asin[0,5])[0,5] + Digest::MD5.hexdigest(asin[5,5])[0,5] # code = label_id + 暗号文字列先頭の10文字
    return code
  end

  # user_idの認証
  def correct_user
    if params[:user_id]
      redirect_to(root_path) unless current_user.id.to_s == params[:user_id].to_s
    end
  end

  # adminの認証
  def admin_user
    redirect_to(root_path) unless current_user && current_user.id.to_s == '1'
  end
end
