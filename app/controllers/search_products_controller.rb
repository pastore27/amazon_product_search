# coding: utf-8
class SearchProductsController < ApplicationController

  def show

  end

  def get_products

    keyword        = params[:keyword]
    negative_match = params[:negative_match]
    negative_match.split.each do |word|
      keyword << " -#{word}"
    end

    res = Amazon::Ecs.item_search(
      keyword,
      :search_index   => params[:category],
      :response_group => 'Large',
      :country        => 'jp',
      :item_page      => params[:page]
    )

    @items = []
    res.items.each do |item|
      item_attributes = item.get_element('ItemAttributes')

      title    = item_attributes.get('Title')
      price    = item_attributes.get('ListPrice/Amount')
      headline = item_attributes.get('Brand')

      url = item.get('DetailPageURL')

      features = item_attributes.get_elements('Feature')

      @items.push({
                    'title'    => title,
                    'url'      => url,
                    'price'    => price,
                    'headline' => headline
                  })
    end

    # search_index=Allの時は5ページまでしか取得できない。Amazon APIの仕様
    max_page = params[:category] == "All" ? 5 : 10;
    @page = {
      'last_page'    => res.total_pages > 10 ? max_page : res.total_pages,
      'current_page' => params[:page]
    }

    puts @items

    @search_info = {
      'keyword'        => params[:keyword],
      'negative_match' => params[:negative_match],
      'category'       => params[:category],
      'is_prime'       => params[:is_prime],
      'page'           => params[:page],
      'item_total'     => res.total_results,
      'max_export'     => max_page * 10
    }

  end

end
