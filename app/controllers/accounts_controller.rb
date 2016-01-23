# coding: utf-8
class AccountsController < ApplicationController

  # ユーザがログインしていないとにアクセスできないように
  before_action :authenticate_user!
  before_action :correct_user

  def index
  end

  def update_form
  end

  def update
    user = User.find_by(id: current_user.id)
    user.aws_access_key_id = params['aws_access_key_id']
    user.aws_secret_key    = params['aws_secret_key']
    user.associate_tag     = params['associate_tag']
    user.save

    redirect_to :action => 'index'
  end

end
