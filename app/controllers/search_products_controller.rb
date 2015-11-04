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
      'max_export'     => max_page * 10
    }

    # APIリクエスト
    (res, @items) = req_search_api(@search_info, params['page'])

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

end
