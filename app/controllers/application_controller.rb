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

    # プライム指定でフィルタリング
    ret_items = _filter_by_is_prime(res.items, condition['is_prime'].to_s)

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
  def req_lookup_api(asins)
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

    # プライム指定でフィルタリング
    variation_items = _filter_by_is_prime(res.items, condition['is_prime'].to_s)

    # parent_asinsのものは削除
    variation_items.delete_if { |item| parent_asins.include?(item['asin']) }

    return variation_items
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

    insert_item = {
      'asin'         => item.get('ASIN'),
      'jan'          => item_attributes ? item_attributes.get('EAN') : '',
      'title'        => item_attributes ? item_attributes.get('Title') : '',
      'url'          => item.get('DetailPageURL'),
      'price'        => item_attributes ? item_attributes.get('ListPrice/Amount') : '',
      'headline'     => item_attributes ? item_attributes.get('Brand') : '',
      'features'     => item_attributes ? item_attributes.get_array('Feature') : '',
      'is_prime'     => is_prime,
      'availability' => availability,
      'main_img_url' => main_img_url,
      'sub_img_urls' => sub_img_urls
    }

    return insert_item
  end

  def _filter_by_is_prime(items, is_prime)
    ret_items = []
    items.each do |item|
      insert_item = _format_item(item)
      if is_prime == '1' then
        if insert_item['is_prime'].to_s == '1' then
          ret_items.push(insert_item)
        end
      else
        ret_items.push(insert_item)
      end
    end
    return ret_items
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
        csv_body['name']        = item['title']
        csv_body['code']        = item['asin']
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

        csv << csv_body.values_at(*csv_header)
      end
    end

    return csv_str
  end

  def create_out_stock_csv_str(asins)
    csv_header = %w/ code /

    csv_str = CSV.generate do |csv|
      # header の追加
      csv << csv_header
      # body の追加
      asins.each do |asin|
        csv_body = {}
        csv_body['code'] = asin

        csv << csv_body.values_at(*csv_header)
      end
    end

    return csv_str
  end

end
