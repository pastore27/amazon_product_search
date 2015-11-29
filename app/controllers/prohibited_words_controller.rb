# coding: utf-8
class ProhibitedWordsController < ApplicationController

  # ユーザがログインしていないとにアクセスできないように
  before_action :authenticate_user!

  def index
    @prohibited_words = ProhibitedWord.where(user_id: current_user.id)
  end

  def create_form

  end

  def create
    prohibited_word = ProhibitedWord.new(
      :user_id => current_user.id,
      :name    => params['name']
    )
    prohibited_word.save

    redirect_to :action => 'index'
  end

  def delete
    prohibited_word = ProhibitedWord.find_by(id: params[:id], user_id: current_user.id)
    prohibited_word.destroy if prohibited_word.present?

    redirect_to :action => 'index'
  end

end
