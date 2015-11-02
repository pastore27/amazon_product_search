class SearchProductsController < ApplicationController

  def show

  end

  def get_products
    res = Amazon::Ecs.item_search(
      params[:keyword],
      :search_index   => params[:category],
      :response_group => 'Large',
      :country        => 'jp',
      :item_page      => params[:page]
    )

    @items = []
    res.items.each do |item|

      puts item
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

    @item_total = res.total_results

    @page = {
      'last_page'    => res.total_pages > 10 ? 10 : res.total_pages,
      'current_page' => params[:page]
    }

    puts @items
  end

end
