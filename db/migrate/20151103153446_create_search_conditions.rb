class CreateSearchConditions < ActiveRecord::Migration
  def change
    create_table :search_conditions do |t|
      t.string  :label_id, :null => false
      t.string  :keyword
      t.string  :negative_match
      t.string  :category, :null => false
      t.integer :is_prime, :null => false

      t.timestamps
    end
  end
end
