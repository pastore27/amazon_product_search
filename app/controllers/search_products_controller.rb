class SearchProductsController < ApplicationController

  def show
    res = Amazon::Ecs.item_search('ruby', :search_index => 'All')

    puts res
  end

end
