class AddUserIdColumnToItems < ActiveRecord::Migration
  def change
    add_column :items, :user_id, :integer, :after => :id, :null => false

    add_index :items, [:user_id, :asin]
  end
end
