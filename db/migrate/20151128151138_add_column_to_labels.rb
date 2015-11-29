class AddColumnToLabels < ActiveRecord::Migration
  def change
    add_column :labels, :user_id, :integer, :after => :id, :null => false
  end
end
