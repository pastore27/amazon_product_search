# coding: utf-8
class SearchProductsController < ApplicationController

  def show
    @search_conditions = SearchCondition.all
  end

  def get_products

    # search_index=Allの時は5ページまでしか取得できない。Amazon APIの仕様
    max_page = params[:category] == "All" ? 5 : 10;

    @search_info = {
      'keyword'        => params['keyword'],
      'negative_match' => params['negative_match'],
      'category'       => params['category'],
      'is_prime'       => params['is_prime'].to_i,
      'page'           => params['page'],
      'max_export'     => max_page * 10
    }

    # APIリクエスト
    (res, @items) = req_api(@search_info)

    @search_info['item_total'] = res.total_results

    @page = {
      'last_page'    => res.total_pages > 10 ? max_page : res.total_pages,
      'current_page' => params['page'].to_i
    }
    @labels = Label.all
  end

  def create_search_condition
    search_condition = SearchCondition.new(
      :label_id       => params['label_id'],
      :keyword        => params['keyword'],
      :negative_match => params['negative_match'],
      :category       => params['category'],
      :is_prime       => params['is_prime']
    )
    search_condition.save

    redirect_to :action => 'show'
  end

  def req_api(condition)
    search_word    = ''
    keyword        = condition['keyword']
    negative_match = condition['negative_match']

    keyword.split.each do |word|
      search_word << " #{word}"
    end
    negative_match.split.each do |word|
      search_word << " -#{word}"
    end

    res = Amazon::Ecs.item_search(
      search_word,
      :search_index   => condition['category'],
      :response_group => 'Large',
      :country        => 'jp',
      :item_page      => condition['page']
    )

    items = []
    res.items.each do |item|
      item_attributes = item.get_element('ItemAttributes')

      title    = item_attributes.get('Title')
      price    = item_attributes.get('ListPrice/Amount')
      headline = item_attributes.get('Brand')
      url      = item.get('DetailPageURL')
      features = item_attributes.get_elements('Feature')

      items.push({
                   'title'    => title,
                   'url'      => url,
                   'price'    => price,
                   'headline' => headline
                 })
    end

    return res, items
  end
end
