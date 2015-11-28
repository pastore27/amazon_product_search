class Users::RegistrationsController < Devise::RegistrationsController

  prepend_before_filter :require_no_authentication, :only => [:cancel]
  prepend_before_filter :authenticate_scope!, :only => [:new, :create ,:edit, :update, :destroy]
  before_action :admin_user, :only => [:new]

  def index
    super
  end

  def destroy
    user = User.find_by(id: params[:id])
    user.destroy if user.present?

    redirect_to :back
  end

end
