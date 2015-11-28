class CreateProhibitedWords < ActiveRecord::Migration
  def change
    create_table :prohibited_words do |t|

      t.timestamps
    end
  end
end
