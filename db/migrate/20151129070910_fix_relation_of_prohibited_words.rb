# coding: utf-8
class FixRelationOfProhibitedWords < ActiveRecord::Migration
  def change
    # usersとprohibited_wordsの紐付け(1対多)
    remove_column :prohibited_words, :user_id, :integer
    add_reference :prohibited_words, :user, :after => :id, :null => false, index: true, foreign_key: true
  end
end
