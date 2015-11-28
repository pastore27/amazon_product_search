# coding: utf-8
class ProhibitedWordsController < ApplicationController

  # ユーザがログインしていないとにアクセスできないように
  before_action :authenticate_user!
  before_action :admin_user

  def show
    @prohibited_words = ProhibitedWord.all
  end

  def create_form

  end

  def create
    prohibited_word = ProhibitedWord.new(
      :name => params['name']
    )
    prohibited_word.save

    redirect_to :action => 'show'
  end

  def delete
    prohibited_word = ProhibitedWord.find_by(id: params[:id])
    prohibited_word.destroy if prohibited_word.present?

    redirect_to :action => 'show'
  end

end
