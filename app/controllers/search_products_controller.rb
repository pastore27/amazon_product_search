# coding: utf-8
class SearchProductsController < ApplicationController

  def show
    @search_conditions = SearchCondition.all
  end

  def get_products
    @search_info = {
      'keyword'        => params['keyword'],
      'negative_match' => params['negative_match'],
      'category'       => params['category'],
      'is_prime'       => params['is_prime'].to_i
    }

    # search_index=Allの時は5ページまでしか取得できない。Amazon APIの仕様
    max_page = params[:category] == "All" ? 5 : 10;

    # APIリクエスト
    @items = []
    (1..max_page).each do |page|
      @items.concat(req_search_api(@search_info, page))
      # Amazon APIの規約に従う
      sleep(1)
    end

    @search_info['item_total'] = @items.length
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

end
