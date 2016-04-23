# coding: utf-8
require 'amazon/ecs'

module Helper::AmazonEcs

  def aws_api_init(user)
    Amazon::Ecs.options = {
      :AWS_access_key_id => user[:aws_access_key_id],
      :AWS_secret_key    => user[:aws_secret_key],
      :associate_tag     => user[:associate_tag]
    }
  end

  def req_search_api(user, condition, page)
    aws_api_init(user)

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
        sleep(3)
        retry
      else
        return []
      end
    end

    ret_items = []
    prohibited_words = ProhibitedWord.where(user_id: user[:id])
    res.items.each do |item|
      insert_item = _format_item(item)
      # search_condition条件を追加する (商品追加の際に利用するため)
      insert_item['search_condition_id'] = condition['id']
      next unless _validate_item(insert_item, condition['is_prime'].to_s, prohibited_words, condition['min_offer_count'].to_s)
      ret_items.push(insert_item)
    end

    # 類似商品を取得
    ret_items.concat(_get_similary_items(user, ret_items, condition, prohibited_words))

    # 色違いの商品の取得
    parent_asins = []
    res.items.each do |item|
      parent_asins.push(item.get('ParentASIN')) if item.get('ParentASIN')
    end
    ret_items.concat(_get_variation_items(user, parent_asins, condition, prohibited_words))

    # 重複を削除する
    ret_items.uniq! {|item| item['asin']}

    return ret_items
  end

  # asinsの配列から商品情報を取得する
  # codeを生成するために、label_idを渡してもらう必要がある
  def req_lookup_api(user, asins, label_id)
    aws_api_init(user)

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
          sleep(3)
          retry
        else
          next
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

  # 商品チェックも行う
  def req_lookup_api_with_item_check(user, asins, label_id, min_offer_count)
    aws_api_init(user)

    in_stock_items     = []
    invalid_items = []
    prohibited_words   = ProhibitedWord.where(user_id: user[:id])

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
          sleep(3)
          retry
        else
          next
        end
      end

      res.items.each do |item|
        insert_item = _format_item(item)
        # codeを生成する
        insert_item['code'] = generate_code(insert_item['asin'], label_id)
        _validate_item(insert_item, nil, prohibited_words, min_offer_count) ? in_stock_items.push(insert_item) : invalid_items.push(insert_item)
      end
    end

    return {
      :in_stock_items => in_stock_items,
      :invalid_items  => invalid_items
    }
  end

  # parent_asinsの配列から色違いの商品情報を取得する。(配列を返す)
  # parent_asinsのものは削除
  def _get_variation_items(user, parent_asins, condition, prohibited_words)
    aws_api_init(user)

    retry_count = 0
    begin
      res = Amazon::Ecs.item_lookup(parent_asins.join(','),
                                    :response_group => 'Variations',
                                    :country        => 'jp'
                                   )
    rescue
      retry_count += 1
      if retry_count < 5
        sleep(3)
        retry
      else
        return []
      end
    end

    variation_items  = []

    res.items.each do |item|
      insert_item = _format_item(item)
      # search_condition条件を追加する (商品追加の際に利用するため)
      insert_item['search_condition_id'] = condition['id']
      next unless _validate_item(insert_item, condition['is_prime'].to_s, prohibited_words, condition['min_offer_count'].to_s)
      variation_items.push(insert_item)
    end

    # parent_asinsのものは削除
    variation_items.delete_if { |item| parent_asins.include?(item['asin']) }

    return variation_items
  end

  # 類似商品情報を取得する。
  def _get_similary_items(user, items, condition, prohibited_words)
    aws_api_init(user)

    asins = items.map { |item| item['asin'] }

    valid_items  = []
    asins.each do |ele|
      retry_count = 0
      begin
        res = Amazon::Ecs.similarity_lookup(ele,
                                            :response_group => 'Large',
                                            :country        => 'jp'
                                           )
      rescue
        retry_count += 1
        if retry_count < 5
          sleep(3)
          retry
        else
          return []
        end
      end

      res.items.each do |item|
        insert_item = _format_item(item)
        # search_condition条件を追加する (商品追加の際に利用するため)
        insert_item['search_condition_id'] = condition['id']
        next unless _validate_item(insert_item, condition['is_prime'].to_s, prohibited_words, condition['min_offer_count'].to_s)
        valid_items.push(insert_item)
      end
    end

    return valid_items
  end

  def _validate_item(item, specified_is_prime, prohibited_words, min_offer_count)
    # プライム指定でフィルタリング
    return false  if (specified_is_prime == '1') && !_is_prime(item['is_prime'].to_s)
    # 在庫状況でフィルタリング
    return false unless _validate_item_availability(item['availability'])
    # 金額が取れていなければ、取得しない
    return false if item['price'].to_s == '0'
    # アダルト商品であれば、取得しない
    return false if item['is_adult'].to_s == '1'
    # 禁止ワードがあれば、取得しない
    return false if _include_prohibited_word(item, prohibited_words)
    # 新品出品数が指定数より少なければ、取得しない
    return false unless _validate_offer_count(item['offer_count'].to_s, min_offer_count)

    return true
  end

  def _include_prohibited_word(item, prohibited_words)
    prohibited_words.each do |prohibited_word|
      return true if "#{item['title']} #{item['headline']} #{item['features'].join(' ')}" =~ /#{prohibited_word.name}/
    end
    return false
  end

  def _format_item(item)
    item_attributes = item.get_element('ItemAttributes')
    main_img_url    = item.get('LargeImage/URL')
    sub_img_urls    = item.get_array('ImageSets/ImageSet/LargeImage/URL')
    # img_urlsにはmain_img_urlも含まれるので消す
    sub_img_urls.delete(main_img_url) if sub_img_urls

    offer_summary = item.get_element('OfferSummary')
    offer_listing = item.get_element('Offers/Offer/OfferListing')
    is_prime = offer_listing ? offer_listing.get('IsEligibleForPrime') : 0
    availability = offer_listing ? offer_listing.get('Availability') : 0
    price = offer_listing ? offer_listing.get('Price/Amount') : 0
    sale_price = offer_listing ? offer_listing.get('SalePrice/Amount') : 0

    insert_item = {
      'asin'         => item.get('ASIN'),
      'jan'          => item_attributes ? item_attributes.get('EAN') : '',
      'title'        => item_attributes ? item_attributes.get('Title') : '',
      'url'          => item.get('DetailPageURL'),
      'price'        => sale_price || price,
      'headline'     => item_attributes ? item_attributes.get('Brand') : '',
      'features'     => item_attributes ? item_attributes.get_array('Feature') : '',
      'is_prime'     => is_prime,
      'is_adult'     => item_attributes ? item_attributes.get('IsAdultProduct') : 0,
      'availability' => availability,
      'main_img_url' => main_img_url,
      'sub_img_urls' => sub_img_urls,
      'offer_count'  => offer_summary ? offer_summary.get('TotalNew') : 0
    }

    return insert_item
  end

  def _is_prime(is_prime)
    is_prime == '1'
  end

  def _validate_item_availability(availability)
    ["在庫あり。","通常1～2営業日以内に発送","通常1～3営業日以内に発送","通常2～3営業日以内に発送"].include?(availability)
  end

  # プライムだったものが、プライムでなくなった場合、不正商品とする
  def validate_item_status_of_is_prime(asin, is_prime_now)
    unless is_prime_now == '1' then
      stored_item = Item.find_by(asin: asin)
      return stored_item.is_prime.to_s == '1' ? false : true
    end
    true
  end

  def _validate_item_stock(item)
    _validate_item_availability(item['availability']) && validate_item_status_of_is_prime(item['asin'], item['is_prime'].to_s)
  end

  def _validate_offer_count(offer_count, min_offer_count)
    min_offer_count.to_i <= offer_count.to_i
  end

  def fetch_asins_by_label(label_id)
    asins = []
    Item.joins(:search_condition).where(search_conditions: {label_id: label_id}).each do |item|
      asins.push(item.asin)
    end
    return asins
  end

  def delete_items_by_codes(codes)
    Item.delete_all(code: codes)
  end

  def extract_invalid_item_codes(items, prohibited_words, min_offer_count)
    invalid_item_codes = []
    items.each do |item|
      next if _validate_item_stock(item) && !_include_prohibited_word(item, prohibited_words) && _validate_offer_count(item['offer_count'].to_s, min_offer_count)
      invalid_item_codes.push(item['code'])
    end
    return invalid_item_codes
  end

  def generate_tmp_zip_file_name()
    Rails.root.join("tmp/zip/#{Time.now}.zip").to_s
  end

  # csv出力オプションの生成
  def generate_csv_option(params)
    csv_option = {
      'path'               => params['path'],
      'explanation'        => params['explanation'],
      'price_option_unit'  => params['price_option_unit'],
      'price_option_value' => params['price_option_value'].to_f,
    }
  end

  def send_zip_file(tmp_zip, file_name)
    send_file(tmp_zip,
              :type => 'application/zip',
              :filename => NKF::nkf('--sjis -Lw', file_name))
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

  def create_invalid_items_csv_str(codes)
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
    label_id.to_s + Digest::MD5.hexdigest(asin[0,5])[0,5] + Digest::MD5.hexdigest(asin[5,5])[0,5] # code = label_id + 暗号文字列
  end

end
