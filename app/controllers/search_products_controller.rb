class SearchProductsController < ApplicationController

  def show

  end

  def get_products
    res = Amazon::Ecs.item_search('ruby', :search_index => 'All')

    puts params[:keyword]
    puts res
  end

end
