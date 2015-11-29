# coding: utf-8
class LabelsController < ApplicationController

  # ユーザがログインしていないとにアクセスできないように
  before_action :authenticate_user!
  before_action :correct_user

  def index
    @labels = Label.where(user_id: current_user.id)
  end

  def create_form

  end

  def create
    label = Label.new(
      :user_id => current_user.id,
      :name    => params['name']
    )
    label.save

    redirect_to :action => 'index'
  end

  def update_form
    @label = Label.find_by(id: params[:id], user_id: current_user.id)
  end

  def update
    label = Label.find_by(id: params[:id], user_id: current_user.id)
    label.name = params['name']
    label.save

    redirect_to :action => 'index'
  end

  def delete
    label = Label.find_by(id: params[:id], user_id: current_user.id)
    label.destroy if label.present? # 紐付く検索条件、商品情報も削除される

    redirect_to :action => 'index'
  end

  def search_conditions
    @label = Label.find_by(id: params[:id], user_id: current_user.id)
    @search_conditions = SearchCondition.where(label_id: params[:id])
  end

  def delete_search_condition
    search_condition = SearchCondition.find_by(id: params[:search_condition_id])
    search_condition.destroy if search_condition.present? # 紐付く商品情報も削除される

    redirect_to :action => 'search_conditions', :id => params[:id]
  end

end
