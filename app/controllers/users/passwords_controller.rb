class Users::PasswordsController < Devise::PasswordsController
  before_action :admin_user
end
