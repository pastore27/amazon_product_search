class SearchProductsController < ApplicationController

  def show

  end

  def get_products
    res = Amazon::Ecs.item_search(
      params[:keyword],
      :search_index   => params[:category],
      :response_group => 'Large',
      :country        => 'jp'
    )

    puts res.first_item

    @items = []
    res.items.each do |item|
      item_attributes = item.get_element('ItemAttributes')

      title = item_attributes.get('Title')
      price = item_attributes.get('ListPrice/Amount')

      url = item.get('DetailPageURL')

      puts title, price, url

      @items.push({ 'title' => title, 'price' => price, 'url' => url })
    end

    puts @items
  end

end
