# coding: utf-8
class BulksController < ApplicationController

  # ユーザがログインしていないとにアクセスできないように
  before_action :authenticate_user!
  before_action :correct_user

  def index

  end

end
