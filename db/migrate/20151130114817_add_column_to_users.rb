class AddColumnToUsers < ActiveRecord::Migration
  def change
    add_column :users, :memo, :string, :after => :last_sign_in_ip
  end
end
