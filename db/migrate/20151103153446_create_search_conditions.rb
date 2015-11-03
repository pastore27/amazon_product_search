class CreateSearchConditions < ActiveRecord::Migration
  def change
    create_table :search_conditions do |t|

      t.timestamps
    end
  end
end
