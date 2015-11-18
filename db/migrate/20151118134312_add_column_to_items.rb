class AddColumnToItems < ActiveRecord::Migration
  def change
    add_column :items, :code, :string, :after => :asin
  end
end
