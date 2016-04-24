# coding: utf-8
class SearchProductsController < ApplicationController

  # ユーザがログインしていないとにアクセスできないように
  before_action :authenticate_user!

  protect_from_forgery except: :get_products_by_asins

  def index
    @search_conditions = SearchCondition.all
  end

  def get_products
    @search_info = {
      'keyword'         => params['keyword'],
      'negative_match'  => params['negative_match'],
      'category'        => params['category'],
      'is_prime'        => params['is_prime'],
      'min_offer_count' => params['min_offer_count']
    }

    # search_index=Allの時は5ページまでしか取得できない。Amazon APIの仕様
    max_page = params[:category] == "All" ? 5 : 10;

    # APIリクエスト
    @items = []
    (1..max_page).each do |page|
      @items.concat(req_search_api(to_user_hash(current_user), @search_info, page))
      # Amazon APIの規約に従う
      sleep(1)
    end

    @search_info['item_total'] = @items.length
    @labels = Label.where(user_id: current_user.id)
  end

  def create_search_condition
    search_condition = SearchCondition.new(
      :label_id        => params['label_id'],
      :keyword         => params['keyword'],
      :negative_match  => params['negative_match'],
      :category        => params['category'],
      :is_prime        => params['is_prime'],
      :min_offer_count => params['min_offer_count'],
    )
    search_condition.save

    redirect_to :action => 'index'
  end

  def form_for_search_by_seller_id

  end

  def get_products_by_asins
    @search_info = {
      'seller_id'       => params['seller_id'],
      'seller_name'     => params['seller_name'],
      'is_prime'        => params['is_prime'],
      'min_offer_count' => params['min_offer_count'],
    }
    @items = params['asins'] ? req_lookup_api(to_user_hash(current_user), params['asins'], 1, @search_info) : [] # dummyのlabel_idを渡す;
    @item_total = @items.length
  end

  def create_label_and_search_condition
    label = Label.new(
      :user_id => current_user.id,
      :name    => '出品者ID検索: ' + params['seller_name'] + '(' + params['seller_id'] + ')'
    )
    if label.save
      search_condition = SearchCondition.new(
        :label_id        => label.id,
        :category        => '',
        :is_prime        => params['is_prime'],
        :min_offer_count => params['min_offer_count'],
        :seller_id       => params['seller_id'],
      )
      search_condition.save
    end

    redirect_to :action => 'form_for_search_by_seller_id'
  end

end
