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
        fetched_items.concat(req_search_api(condition, page)[1])
        # Amazon APIの規約に従う
        sleep(1)
      end
    end

    # csv出力するデータを選定
    # dbに保存
    @csv_items = []
    fetched_items.each do |fetched_item|
      item = Item.new(
        :label_id => label_id,
        :asin     => fetched_item['asin']
      )
      if item.save
        @csv_items.push({
                          'title'    => fetched_item['title'],
                          'price'    => fetched_item['price'],
                          'headline' => fetched_item['headline']
                        })
      else
        next
      end
    end

    # csv出力オプション
    

    # csv出力
    respond_to do |format|
      format.csv { send_data render_to_string, filename: "ここにファイル名.csv", type: :csv }
    end
  end

end
