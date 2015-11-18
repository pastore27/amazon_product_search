class Users::RegistrationsController < Devise::RegistrationsController
  prepend_before_filter :require_no_authentication, :only => [ :cancel]
  prepend_before_filter :authenticate_scope!, :only => [:new, :create ,:edit, :update, :destroy]

  def new
    if current_user.id.to_s == '1' then
      super
    else
      redirect_to '/labels'
    end
  end

  def create
    super
  end

end
