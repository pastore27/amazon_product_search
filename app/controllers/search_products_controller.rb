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
      'is_prime'       => params['is_prime']
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

    ### 検索条件追加の際に商品一覧も追加する ###

    # ラベルに紐づく検索条件を取得
    label_id = params['label_id']
    label = Label.find(label_id)
    search_conditions = SearchCondition.where(label_id: label_id)

    # Amazon APIよりデータを取得
    # APIリクエスト数の最大値は、search_conditions.length * 10
    fetched_items = []
    search_conditions.each do |condition|
      max_page = condition['category'] == "All" ? 5 : 10;
      (1..max_page).each do |page|
        fetched_items.concat(req_search_api(condition, page))
        # Amazon APIの規約に従う
        sleep(1)
      end
    end
    # 新規商品データのみdbに保存
    fetched_items.each do |fetched_item|
      item = Item.new(
        :label_id => label_id,
        :asin     => fetched_item['asin'],
        :name     => fetched_item['title'],
        :is_prime => fetched_item['is_prime']
      )
      unless item.save
        next
      end
    end

    redirect_to :action => 'show'
  end

end
