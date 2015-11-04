# coding: utf-8
class ExportProductsController < ApplicationController

  def show
    @labels = Label.all
  end

  def download
    label_id = params['label_id']

    search_conditions = SearchCondition.where(label_id: label_id)
    puts search_conditions.length

    fetched_items = []
    search_conditions.each do |condition|
      max_page = condition['category'] == "All" ? 5 : 10;
      (1..max_page).each do |page|
        fetched_items.concat(req_search_api(condition, page)[1])
        # Amazon APIの規約に従う
        sleep(1)
      end
    end

    @csv_items = []
    # dbに保存
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

    # csv出力
    respond_to do |format|
      format.csv { send_data render_to_string, filename: "ここにファイル名.csv", type: :csv }
    end
  end

end
