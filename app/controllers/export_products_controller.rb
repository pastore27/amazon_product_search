# coding: utf-8
class ExportProductsController < ApplicationController

  def show
    @labels = Label.all
  end

  def download
    label_id = params['label_id']

    search_conditions = SearchCondition.where(label_id: label_id)
    puts search_conditions.length

    @items = []
    search_conditions.each do |condition|
      max_page = condition['category'] == "All" ? 5 : 10;
      (1..max_page).each do |page|
        (req, items) = req_search_api(condition, page)
        @items.concat(items)
        # Amazon APIの規約に従う
        sleep(1)
      end
    end
    puts @items

    respond_to do |format|
      format.csv { send_data render_to_string, filename: "ここにファイル名.csv", type: :csv }
    end
  end

end
