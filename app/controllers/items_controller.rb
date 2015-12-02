# coding: utf-8
class ItemsController < ApplicationController
  PER = 50

  # ユーザがログインしていないとにアクセスできないように
  before_action :authenticate_user!
  before_action :correct_user

  def index
    @label = Label.find_by(id: params[:label_id])
    @items = Item.joins(:search_condition).where(search_conditions: {label_id: params[:label_id]}).page(params[:page]).per(PER).order('id ASC')
    @page  = params[:page] || 1
  end

  def add_items
    # ラベルに紐づく検索条件を取得
    label_id = params[:label_id]
    label = Label.find_by(id: label_id, user_id: current_user.id)
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

    # 新規商品データをdbに保存
    fetched_items.each do |fetched_item|
      asin = fetched_item['asin']
      code = generate_code(asin, label_id)
      item = Item.new(
        :user_id              => current_user.id,
        :search_condition_id => fetched_item['search_condition_id'],
        :asin                 => asin,
        :code                 => code,
        :name                 => fetched_item['title'].byteslice(0,255).scrub(''), # nameカラムは255byte以内
        :is_prime             => fetched_item['is_prime']
      )
      if item.save
        csv_items.push({
                         'asin'         => asin,
                         'code'         => code,
                         'jan'          => fetched_item['jan'],
                         'title'        => fetched_item['title'],
                         'price'        => fetched_item['price'].to_i,
                         'headline'     => fetched_item['headline'],
                         'features'     => fetched_item['features'],
                         'main_img_url' => fetched_item['main_img_url'],
                         'sub_img_urls' => fetched_item['sub_img_urls']
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
      # csvファイルの追加
      count = 1
      csv_strs.each do |csv_str|
        ar.add_buffer(NKF::nkf('--sjis -Lw', "新規追加商品(#{label.name}_#{(count.to_i - 1) * 1000 + 1}~#{count.to_i * 1000}件).csv"), NKF::nkf('--sjis -Lw', csv_str))
        count += 1
      end
    end

    send_file(tmp_zip,
              :type => 'application/zip',
              :filename => NKF::nkf('--sjis -Lw', "新規追加商品(#{label.name}).zip"))
  end

  def download_items
    # ラベルに紐づく検索条件を取得
    label_id = params[:label_id]
    label = Label.find_by(id: label_id, user_id: current_user.id)

    # csv出力するデータを選定
    csv_items = []

    # 保存済みの商品データを取得
    # ここでdbからデータを取得し、apiリクエストを送る
    asins = []
    Item.joins(:search_condition).where(search_conditions: {label_id: params[:label_id]}).each do |item|
      asins.push(item.asin)
    end

    # item_lookup APIを叩く
    stored_items = req_lookup_api(asins, label_id) # codeを生成するために、label_idを渡す必要がある
    stored_items.each do |stored_item|
      csv_items.push({
                       'asin'         => stored_item['asin'],
                       'code'         => stored_item['code'],
                       'jan'          => stored_item['jan'],
                       'title'        => stored_item['title'],
                       'price'        => stored_item['price'].to_i,
                       'headline'     => stored_item['headline'],
                       'features'     => stored_item['features'],
                       'main_img_url' => stored_item['main_img_url'],
                       'sub_img_urls' => stored_item['sub_img_urls']
                     })
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
      # csvファイルの追加
      count = 1
      csv_strs.each do |csv_str|
        ar.add_buffer(NKF::nkf('--sjis -Lw', "商品一覧(#{label.name}_#{(count.to_i - 1) * 1000 + 1}~#{count.to_i * 1000}件).csv"), NKF::nkf('--sjis -Lw', csv_str))
        count += 1
      end
    end

    send_file(tmp_zip,
              :type => 'application/zip',
              :filename => NKF::nkf('--sjis -Lw', "商品一覧(#{label.name}).zip"))
  end

  def download_imgs
    # ラベルに紐づく検索条件を取得
    label_id = params[:label_id]
    label = Label.find_by(id: label_id, user_id: current_user.id)

    # 保存済みの商品データを取得
    # ここでdbからデータを取得し、apiリクエストを送る
    asins = []
    Item.joins(:search_condition).where(search_conditions: {label_id: params[:label_id]}).page(params[:page]).per(PER).order('id ASC').each do |item|
      asins.push(item.asin)
    end

    # item_lookup APIを叩く
    export_items = req_lookup_api(asins, label_id) # codeを生成するために、label_idを渡す必要がある

    # img出力の前処理
    img_data = []
    # img_data = {
    #   asin: export_item['asin'],
    #   main_img: data,
    #   sub_img: [data, data, data,..],
    # }
    export_items.each do |export_item|
      item_img_data = { code: export_item['code'] }
      if export_item['main_img_url'] then
        open(export_item['main_img_url']) do |main_img_data|
          item_img_data['main_img'] = main_img_data.read
        end
      end
      item_img_data['sub_img'] = []
      if export_item['sub_img_urls'] then
        export_item['sub_img_urls'].each do |url|
          open(url) do |sub_img_data|
            item_img_data['sub_img'].push(sub_img_data.read)
          end
        end
      end
      img_data.push(item_img_data)
    end

    tmp_zip = Rails.root.join("tmp/zip/#{Time.now}.zip").to_s
    Zip::Archive.open(tmp_zip, Zip::CREATE) do |ar|
      img_data.each do |data|
        # main画像
        if data['main_img'] then
          ar.add_buffer(NKF::nkf('--sjis -Lw', "#{data[:code]}.jpg"), data['main_img'])
        end
        # sub画像
        if data['sub_img'] then
          count = 1
          data['sub_img'].each do |ele|
            ar.add_buffer(NKF::nkf('--sjis -Lw', "#{data[:code]}_#{count}.jpg"), ele)
            count += 1
          end
        end
      end
    end

    send_file(tmp_zip,
              :type => 'application/zip',
              :filename => NKF::nkf('--sjis -Lw', "商品画像(#{label.name}).zip"))
  end

  def check_stock
    # ラベルに紐づく検索条件を取得
    label_id = params[:label_id]
    label = Label.find_by(id: label_id, user_id: current_user.id)

    # 保存済みの商品データを取得
    # ここでdbからデータを取得し、apiリクエストを送る
    asins = []
    Item.joins(:search_condition).where(search_conditions: {label_id: params[:label_id]}).page(params[:page]).per(PER).order('id ASC').each do |item|
      asins.push(item.asin)
    end

    # item_lookup APIを叩く
    fetched_items = req_lookup_api(asins, label_id)

    out_of_stock_codes = []
    fetched_items.each do |fetched_item|
      # プライムだったものが、プライムでなくなった場合、在庫切れとする
      unless fetched_item['is_prime'] then
        stored_item = Item.find_by(asin: fetched_item['asin'])
        if stored_item.is_prime then
          out_of_stock_codes.push(fetched_item['code'])
          next
        end
      end

      unless ["在庫あり。","通常1～2営業日以内に発送","通常1～3営業日以内に発送","通常2～3営業日以内に発送"].include?(fetched_item['availability']) then
        out_of_stock_codes.push(fetched_item['code'])
        next
      end
    end

    tmp_zip = Rails.root.join("tmp/zip/#{Time.now}.zip").to_s
    Zip::Archive.open(tmp_zip, Zip::CREATE) do |ar|
      # csvファイルの追加
      ar.add_buffer(NKF::nkf('--sjis -Lw', "在庫切れ商品(#{label.name}).csv"), NKF::nkf('--sjis -Lw', create_out_stock_csv_str(out_of_stock_codes)))
    end

    # 在庫なし商品の削除
    Item.delete_all(code: out_of_stock_codes)

    send_file(tmp_zip,
              :type => 'application/zip',
              :filename => NKF::nkf('--sjis -Lw', "在庫切れ商品(#{label.name}).zip"))
  end

  def delete
    item = Item.find_by(id: params[:item_id], user_id: current_user.id)
    item.destroy if item.present?

    redirect_to :action => 'index'
  end

end
