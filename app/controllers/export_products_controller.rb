# coding: utf-8
class ExportProductsController < ApplicationController

  def show
    @labels = Label.all
  end

  def download
    # ラベルに紐づく検索条件を取得
    label_id = params['label_id']
    label = Label.find(label_id)
    search_conditions = SearchCondition.where(label_id: label_id)

    # Amazon APIよりデータを取得
    # APIリクエスト数の最大値は、search_conditions.length * 10
    fetched_items = []
    search_conditions.each do |condition|
      max_page = condition['category'] == "All" ? 5 : 10;
      (1..max_page).each do |page|
        fetched_items.concat(req_search_api(condition, page))
        # Amazon APIの規約に従う
        sleep(1)
      end
    end

    # csv出力するデータを選定
    csv_items = []

    # 保存済みの商品データを取得
    if params['is_all_items'] == 'on' then
      # ここでdbからデータを取得し、apiリクエストを送る
      asins = []
      Item.where(label_id: label_id).each do |item|
        asins.push(item.asin)
      end

      # item_lookup APIを叩く
      stored_items = req_lookup_api(asins)
      stored_items.each do |stored_item|
        csv_items.push({
                          'asin'     => stored_item['asin'],
                          'jan'      => stored_item['jan'],
                          'title'    => stored_item['title'],
                          'price'    => stored_item['price'].to_i,
                          'headline' => stored_item['headline'],
                          'features' => stored_item['features']
                        })
      end
    end

    # 新規商品データをdbに保存
    fetched_items.each do |fetched_item|
      item = Item.new(
        :label_id => label_id,
        :asin     => fetched_item['asin']
      )
      if item.save
        csv_items.push({
                          'asin'     => fetched_item['asin'],
                          'jan'      => fetched_item['jan'],
                          'title'    => fetched_item['title'],
                          'price'    => fetched_item['price'].to_i,
                          'headline' => fetched_item['headline'],
                          'features' => fetched_item['features']
                        })
      else
        next
      end
    end

    # csv出力オプション
    csv_option = {
      'path'               => params['path'],
      'explanation'        => params['explanation'],
      'price_option_unit'  => params['price_option_unit'],
      'price_option_value' => params['price_option_value'].to_f,
    }

    # csv出力
    csv_strs = []
    csv_items.each_slice(1000).to_a.each do |ele|
      csv_strs.push(create_csv_str(ele, csv_option)) if ele
    end

    tmp_zip = Rails.root.join("tmp/zip/#{Time.now}.zip").to_s
    Zip::Archive.open(tmp_zip, Zip::CREATE) do |ar|
      count = 1
      csv_strs.each do |csv_str|
        ar.add_buffer("#{label.name + count.to_s}.csv", NKF::nkf('--sjis -Lw', csv_str))
        count += 1
      end
    end

    send_file(tmp_zip,
              :type => 'application/zip',
              :filename => "#{label.name}.zip")
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

end
