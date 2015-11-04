class CreateItems < ActiveRecord::Migration
  def change
    create_table :items do |t|
      t.integer :label_id, :null => false
      t.string  :asin, :null => false

      t.timestamps
    end
  end
end
