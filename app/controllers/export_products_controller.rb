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
        @items.concat(fetch_items_from_api(condition, page))
        # Amazon APIの規約に従う
        sleep(1)
      end
    end
    puts @items

    respond_to do |format|
      format.csv { send_data render_to_string, filename: "ここにファイル名", type: :csv }
    end
  end

  def fetch_items_from_api(condition, page)
    search_word    = ''
    keyword        = condition['keyword']
    negative_match = condition['negative_match']

    keyword.split.each do |word|
      search_word << word
    end
    negative_match.split.each do |word|
      search_word << " -#{word}"
    end

    retry_count = 0
    begin
      res = Amazon::Ecs.item_search(
        search_word,
        :search_index   => condition['category'],
        :response_group => 'Large',
        :country        => 'jp',
        :item_page      => page
      )
    rescue
      retry_count += 1
      if retry_count < 5
        sleep(5)
        retry
      else
        return false
      end
    end

    items = []
    res.items.each do |item|
      item_attributes = item.get_element('ItemAttributes')

      title    = item_attributes.get('Title')
      price    = item_attributes.get('ListPrice/Amount')
      headline = item_attributes.get('Brand')

      items.push({
                   'title'    => title,
                   'price'    => price,
                   'headline' => headline
                 })
    end

    return items
  end

end
