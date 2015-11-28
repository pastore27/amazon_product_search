# coding: utf-8
class ProhibitedWordsController < ApplicationController

  # ユーザがログインしていないとにアクセスできないように
  before_action :authenticate_user!, only: :show

  def show
    @prohibited_words = ProhibitedWord.all
  end

end
