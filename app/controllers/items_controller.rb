# coding: utf-8
class ItemsController < ApplicationController
  PER = 50

  # ユーザがログインしていないとにアクセスできないように
  before_action :authenticate_user!
  before_action :correct_user

  protect_from_forgery except: :add_items_by_asins

  def index
    @label = Label.find_by(id: params[:label_id])
    @items = Item.joins(:search_condition).where(search_conditions: {label_id: params[:label_id]}).page(params[:page]).per(PER).order('id ASC')
    @label_for_seller_id = SearchCondition.where(label_id: params[:label_id]).where.not(seller_id: nil).count > 0 ? true : false
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
        fetched_items.concat(req_search_api(to_user_hash(current_user), condition, page))
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
                         'contents'     => fetched_item['contents'],
                         'main_img_url' => fetched_item['main_img_url'],
                         'sub_img_urls' => fetched_item['sub_img_urls']
                       })
      else
        next
      end
    end

    # csv出力
    csv_strs = []
    csv_items.each_slice(1000).to_a.each do |ele|
      csv_strs.push(create_csv_str(ele, generate_csv_option(params), current_user.id)) if ele
    end

    tmp_zip = generate_tmp_zip_file_name()
    Zip::Archive.open(tmp_zip, Zip::CREATE) do |ar|
      # csvファイルの追加
      count = 1
      csv_strs.each do |csv_str|
        ar.add_buffer(
          NKF::nkf('--sjis -Lw', "新規追加商品(#{label.name}_#{(count.to_i - 1) * 1000 + 1}~#{count.to_i * 1000}件).csv"),
          NKF::nkf('--sjis -Lw', csv_str)
        )
        count += 1
      end
    end

    send_zip_file(tmp_zip, "新規追加商品(#{label.name}).zip")
  end

  def add_items_by_asins
    # ラベルに紐づく検索条件を取得
    label_id = params[:label_id]
    label = Label.find_by(id: label_id, user_id: current_user.id)
    search_condition = SearchCondition.find_by(label_id: label_id)

    # Amazon APIよりデータを取得
    # APIリクエスト数の最大値は、search_conditions.length * 10
    fetched_items = params['asins'] ? req_lookup_api(to_user_hash(current_user), params['asins'], label_id, search_condition) : []

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
                         'contents'     => fetched_item['contents'],
                         'main_img_url' => fetched_item['main_img_url'],
                         'sub_img_urls' => fetched_item['sub_img_urls']
                       })
      else
        next
      end
    end

    # csv出力
    csv_strs = []
    csv_items.each_slice(1000).to_a.each do |ele|
      csv_strs.push(create_csv_str(ele, generate_csv_option(params), current_user.id)) if ele
    end

    tmp_zip = generate_tmp_zip_file_name()
    Zip::Archive.open(tmp_zip, Zip::CREATE) do |ar|
      # csvファイルの追加
      count = 1
      csv_strs.each do |csv_str|
        ar.add_buffer(
          NKF::nkf('--sjis -Lw', "新規追加商品(#{label.name}_#{(count.to_i - 1) * 1000 + 1}~#{count.to_i * 1000}件).csv"),
          NKF::nkf('--sjis -Lw', csv_str)
        )
        count += 1
      end
    end

    send_zip_file(tmp_zip, "新規追加商品(#{label.name}).zip")
  end

  def download_items
    # ラベルに紐づく検索条件を取得
    label_id = params[:label_id]
    label = Label.find_by(id: label_id, user_id: current_user.id)

    min_offer_count = params[:min_offer_count] ? params[:min_offer_count] : 0

    # csv出力するデータを選定
    csv_items_in_stock = []
    invalid_items      = []

    # item_lookup APIを叩く
    stored_items = req_lookup_api_with_item_check(to_user_hash(current_user), fetch_asins_by_label(label_id), label_id, min_offer_count) # codeを生成するために、label_idを渡す必要がある
    stored_items[:in_stock_items].each do |stored_item|
      # プライムだったものが、プライムでなくなった場合、不正商品とする
      unless validate_item_status_of_is_prime(stored_item['asin'], stored_item['is_prime']) then
        invalid_items.push({ 'code' => stored_item['code'], 'title' => stored_item['title'] })
        next
      end

      csv_items_in_stock.push({
                       'asin'         => stored_item['asin'],
                       'code'         => stored_item['code'],
                       'jan'          => stored_item['jan'],
                       'title'        => stored_item['title'],
                       'price'        => stored_item['price'].to_i,
                       'headline'     => stored_item['headline'],
                       'features'     => stored_item['features'],
                       'contents'     => stored_item['contents'],
                       'main_img_url' => stored_item['main_img_url'],
                       'sub_img_urls' => stored_item['sub_img_urls']
                     })
    end
    stored_items[:invalid_items].each do |item|
      invalid_items.push({ 'code' => item['code'], 'title' => item['title'] })
    end

    # csv出力
    csv_strs = []
    csv_items_in_stock.each_slice(1000).to_a.each do |ele|
      csv_strs.push(create_csv_str(ele, generate_csv_option(params), current_user.id)) if ele
    end

    tmp_zip = generate_tmp_zip_file_name()
    Zip::Archive.open(tmp_zip, Zip::CREATE) do |ar|
      # 商品一覧csvファイルの追加
      count = 1
      csv_strs.each do |csv_str|
        ar.add_buffer(
          NKF::nkf('--sjis -Lw', "商品一覧(#{label.name}_#{(count.to_i - 1) * 1000 + 1}~#{count.to_i * 1000}件).csv"),
          NKF::nkf('--sjis -Lw', csv_str)
        )
        count += 1
      end
      # 不正商品csvファイルの追加
      ar.add_buffer(
        NKF::nkf('--sjis -Lw', "不正商品(#{label.name}).csv"),
        NKF::nkf('--sjis -Lw', create_invalid_items_csv_str(invalid_items))
      )
    end

    send_zip_file(tmp_zip, "商品一覧(#{label.name}).zip")
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
    export_items = req_lookup_api(to_user_hash(current_user), asins, label_id) # codeを生成するために、label_idを渡す必要がある

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
        begin
          open(export_item['main_img_url']) do |main_img_data|
            item_img_data['main_img'] = main_img_data.read
          end
        rescue
          next
        end
      end
      item_img_data['sub_img'] = []
      if export_item['sub_img_urls'] then
        export_item['sub_img_urls'].each do |url|
          begin
            open(url) do |sub_img_data|
              item_img_data['sub_img'].push(sub_img_data.read)
            end
          rescue
            next
          end
        end
      end
      img_data.push(item_img_data)
    end

    tmp_zip = generate_tmp_zip_file_name()
    Zip::Archive.open(tmp_zip, Zip::CREATE) do |ar|
      img_data.each do |data|
        # main画像
        if data['main_img'] then
          ar.add_buffer(
            NKF::nkf('--sjis -Lw', "#{data[:code]}.jpg"),
            data['main_img']
          )
        end
        # sub画像
        if data['sub_img'] then
          count = 1
          data['sub_img'].each do |ele|
            ar.add_buffer(
              NKF::nkf('--sjis -Lw', "#{data[:code]}_#{count}.jpg"),
              ele
            )
            count += 1
          end
        end
      end
    end

    send_zip_file(tmp_zip, "商品画像(#{label.name}).zip")
  end

  def check_items
    # ラベルに紐づく検索条件を取得
    label_id = params[:label_id]
    label    = Label.find_by(id: label_id, user_id: current_user.id)

    min_offer_count = params[:min_offer_count] ? params[:min_offer_count] : 0

    invalid_items = extract_invalid_items(
                      req_lookup_api(
                        to_user_hash(current_user), fetch_asins_by_label(label_id), label_id
                      ),
                      ProhibitedWord.where(user_id: current_user.id),
                      min_offer_count
                    )

    tmp_zip = generate_tmp_zip_file_name()
    Zip::Archive.open(tmp_zip, Zip::CREATE) do |ar|
      ar.add_buffer(
        NKF::nkf('--sjis -Lw', "不正商品(#{label.name}).csv"),
        NKF::nkf('--sjis -Lw', create_invalid_items_csv_str(invalid_items))
      )
    end

    send_zip_file(tmp_zip, "不正商品(#{label.name}).zip")
  end

  def delete
    item = Item.find_by(id: params[:item_id], user_id: current_user.id)
    item.destroy if item.present?

    redirect_to :action => 'index'
  end

  def delete_items
    if params[:csv_file]
      path = params[:csv_file].tempfile.path
      open(path, 'r:cp932:utf-8', undef: :replace) do |f|
        csv = CSV.new(f, :headers => :first_row)
        csv.each do |row|
          next if row.header_row?
          code = row.fields
          item = Item.find_by(user_id: current_user.id, code: code)
          item.destroy if item.present?
        end
      end
    end

    redirect_to :action => 'index'
  end

end
