# coding: utf-8
class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  include Helper::AmazonEcs

  # user_idの認証
  def correct_user
    redirect_to(root_path) if params[:user_id] && ( current_user.id.to_s != params[:user_id].to_s )
  end

  # adminの認証
  def admin_user
    redirect_to(root_path) unless current_user && current_user.id.to_s == '1'
  end

  def to_user_hash(current_user)
    return {
      :id                => current_user.id,
      :aws_access_key_id => current_user.aws_access_key_id,
      :aws_secret_key    => current_user.aws_secret_key,
      :associate_tag     => current_user.associate_tag,
    }
  end

end
