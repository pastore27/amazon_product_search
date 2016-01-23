class AddApiKeyColumnToUsers < ActiveRecord::Migration
  def change
    add_column :users, :aws_access_key_id, :string, :after => :memo
    add_column :users, :aws_secret_key,    :string, :after => :aws_access_key_id
    add_column :users, :associate_tag,     :string, :after => :aws_secret_key
  end
end
