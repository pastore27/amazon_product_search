class SearchProductsController < ApplicationController

  def show

  end

  def get_products
    res = Amazon::Ecs.item_search(
      params[:keyword],
      :search_index => params[:category],
      :country      => 'jp'
    )

    puts res.first_item
  end

end
