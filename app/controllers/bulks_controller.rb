# coding: utf-8
class BulksController < ApplicationController

  # ユーザがログインしていないとにアクセスできないように
  before_action :authenticate_user!
  before_action :correct_user

  def index

  end

  def add_search_conditions
    keywords = params[:keyword]
    count = 1
    keywords.each_slice(10).to_a.each do |ele|
      # ラベルの登録
      label = Label.new(
        :user_id => current_user.id,
        :name    => "#{params['label']}_#{count}"
      )
      label.save
      ele.each do |keyword|
        search_condition = SearchCondition.new(
          :label_id       => label.id,
          :keyword        => keyword,
          :negative_match => params['negative_match'],
          :category       => params['category'],
          :is_prime       => params['is_prime']
        )
        search_condition.save
      end
      count += 1
    end

    redirect_to :action => 'index'
  end

  def check_stock
    # userに紐づく検索条件を取得
    labels = Label.where(user_id: current_user.id)

    fetched_items = []
    labels.each do |label|
      # 保存済みの商品データを取得
      # ここでdbからデータを取得し、apiリクエストを送る
      asins = []
      Item.joins(:search_condition).where(search_conditions: {label_id: label.id}).each do |item|
        asins.push(item.asin)
      end

      # item_lookup APIを叩く
      fetched_items.concat(req_lookup_api(asins, label.id))
    end

    out_of_stock_codes = []
    fetched_items.each do |fetched_item|
      # プライムだったものが、プライムでなくなった場合、在庫切れとする
      unless fetched_item['is_prime'].to_s == '1' then
        stored_item = Item.find_by(asin: fetched_item['asin'])
        if stored_item.is_prime.to_s == '1' then
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
      ar.add_buffer(NKF::nkf('--sjis -Lw', "在庫切れ商品(全ラベル).csv"), NKF::nkf('--sjis -Lw', create_out_stock_csv_str(out_of_stock_codes)))
    end

    # 在庫なし商品の削除
    Item.delete_all(code: out_of_stock_codes)

    send_file(tmp_zip,
              :type => 'application/zip',
              :filename => NKF::nkf('--sjis -Lw', "在庫切れ商品(全ラベル).zip"))
  end
end
