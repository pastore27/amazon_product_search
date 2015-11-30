# coding: utf-8
class UsersController < ApplicationController

  # ユーザがログインしていないとにアクセスできないように
  before_action :authenticate_user!
  before_action :admin_user

  def index
    @users = User.all
  end

  def update_memo_form
    @user = User.find_by(id: params[:user_id])
  end

  def update_memo
    user = User.find_by(id: params[:user_id])
    user.memo = params['memo']
    user.save

    redirect_to :action => 'index'
  end

end
