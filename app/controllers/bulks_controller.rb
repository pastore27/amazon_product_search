# coding: utf-8
class BulksController < ApplicationController

  # ユーザがログインしていないとにアクセスできないように
  before_action :authenticate_user!
  before_action :correct_user

  def index

  end

  def add_search_conditions
    keyword = params[:keyword]
    keywords = keyword.rstrip.split(/\r?\n/).map {|line| line.chomp }
    keywords = keywords.reject(&:blank?)
    count = 1
    # 1ラベルあたり20検索条件
    keywords.each_slice(20).to_a.each do |ele|
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
          :is_prime       => params['is_prime'] || "0"
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

    out_of_stock_codes = []
    labels.each do |label|
      # 保存済みの商品データを取得
      # ここでdbからデータを取得し、apiリクエストを送る
      asins = []
      Item.joins(:search_condition).where(search_conditions: {label_id: label.id}).each do |item|
        asins.push(item.asin)
      end

      out_of_stock_codes.concat(extract_out_of_stock_codes(req_lookup_api(asins, label.id)))
    end

    tmp_zip = Rails.root.join("tmp/zip/#{Time.now}.zip").to_s
    Zip::Archive.open(tmp_zip, Zip::CREATE) do |ar|
      # csvファイルの追加
      ar.add_buffer(NKF::nkf('--sjis -Lw', "在庫切れ商品(全ラベル).csv"), NKF::nkf('--sjis -Lw', create_out_stock_csv_str(out_of_stock_codes)))
    end

    # 在庫なし商品の削除
    delete_items_by_codes(out_of_stock_codes)

    send_file(tmp_zip,
              :type => 'application/zip',
              :filename => NKF::nkf('--sjis -Lw', "在庫切れ商品(全ラベル).zip"))
  end
end
