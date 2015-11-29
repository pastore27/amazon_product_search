class AddColumnToProhibitedWords < ActiveRecord::Migration
  def change
    add_column :prohibited_words, :user_id, :integer, :after => :id, :null => false
  end
end
