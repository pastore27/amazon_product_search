class CreateProhibitedWords < ActiveRecord::Migration
  def change
    create_table :prohibited_words do |t|
      t.string :name, :null => false

      t.timestamps
    end
  end
end
