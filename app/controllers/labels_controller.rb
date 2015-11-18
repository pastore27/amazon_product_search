# coding: utf-8
class LabelsController < ApplicationController

  def show
    @labels = Label.all
  end

  def create_form

  end

  def create
    label = Label.new(
      :name => params['name']
    )
    label.save

    redirect_to :action => 'show'
  end

  def update_form
    @label = Label.find_by(id: params[:id])
  end

  def update
    label = Label.find_by(id: params[:id])
    label.name = params['name']
    label.save

    redirect_to :action => 'show'
  end

  def delete
    label = Label.find_by(id: params[:id])
    label.destroy if label.present?

    # 紐付く検索条件も削除する
    SearchCondition.delete_all(label_id: params[:id])
    # 紐付く商品情報も削除する
    Item.delete_all(label_id: params[:id])

    redirect_to :action => 'show'
  end

  def search_conditions
    @label = Label.find_by(id: params[:id])
    @search_conditions = SearchCondition.where(label_id: params[:id])
  end

  def delete_search_condition
    search_condition = SearchCondition.find_by(id: params[:search_condition_id])
    search_condition.destroy if search_condition.present?

    redirect_to :action => 'search_conditions', :id => params[:id]
  end
end
