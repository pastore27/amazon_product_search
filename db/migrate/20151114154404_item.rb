class Item < ActiveRecord::Migration
  def change
    add_column :items, :name,     :string,  :after => :asin
    add_column :items, :is_prime, :integer, :after => :name
  end
end
