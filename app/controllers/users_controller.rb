# coding: utf-8
class UsersController < ApplicationController

  # ユーザがログインしていないとにアクセスできないように
  before_action :authenticate_user!
  before_action :admin_user

  def index
    @users = User.all
  end

end
