# coding: utf-8
class ExportProductsController < ApplicationController

  def show
    @labels = Label.all
  end

  def download
    # ラベルに紐づく検索条件を取得
    label_id = params['label_id']
    search_conditions = SearchCondition.where(label_id: label_id)
    puts search_conditions.length

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
    @csv_items = []

    # 保存済みの商品データを取得
    if params['is_all_items'] == 'on' then
      puts "ここでdbからデータを取得し、apiリクエストを送る"
      asins = []
      Item.where(label_id: label_id).each do |item|
        asins.push(item.asin)
      end

      # item_lookup APIを叩く
      stored_items = req_lookup_api(asins)
      stored_items.each do |stored_item|
        @csv_items.push({
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
        @csv_items.push({
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
    @csv_option = {
      'path'               => params['path'],
      'explanation'        => params['explanation'],
      'price_option_unit'  => params['price_option_unit'],
      'price_option_value' => params['price_option_value'].to_f,
    }

    # csv出力
    respond_to do |format|
      format.csv { send_data render_to_string, filename: "ここにファイル名.csv", type: :csv }
    end
  end

end
