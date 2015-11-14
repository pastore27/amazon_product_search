# coding: utf-8
class LabelsController < ApplicationController

  def show
    @labels = Label.all
  end

  def create_form

  end

  def create
    label = Label.new(
      :name => params['name']
    )
    label.save

    redirect_to :action => 'show'
  end

  def update_form
    @label = Label.find_by(id: params[:id])
  end

  def update
    label = Label.find_by(id: params[:id])
    label.name = params['name']
    label.save

    redirect_to :action => 'show'
  end

  def delete
    label = Label.find_by(id: params[:id])
    label.destroy

    redirect_to :action => 'show'
  end

  def search_conditions
    @label = Label.find_by(id: params[:id])
    @search_conditions = SearchCondition.where(label_id: params[:id])
  end

  def items
    @label = Label.find_by(id: params[:id])
    @items = Item.where(label_id: params[:id])
  end

  def add_items
    # ラベルに紐づく検索条件を取得
    label_id = params[:id]
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

    # 新規商品データをdbに保存
    fetched_items.each do |fetched_item|
      item = Item.new(
        :label_id => label_id,
        :asin     => fetched_item['asin']
      )
      if item.save
        csv_items.push({
                          'asin'         => fetched_item['asin'],
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
        ar.add_buffer("#{label.name + count.to_s}.csv", NKF::nkf('--sjis -Lw', csv_str))
        count += 1
      end
    end

    send_file(tmp_zip,
              :type => 'application/zip',
              :filename => "#{label.name}.zip")
  end

end
