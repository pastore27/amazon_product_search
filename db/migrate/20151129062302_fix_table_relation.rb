# coding: utf-8
class FixTableRelation < ActiveRecord::Migration
  def change
    # usersとlabelsの紐付け(1対多)
    remove_column :labels, :user_id, :integer
    add_reference :labels, :user, :after => :id, :null => false, index: true, foreign_key: true

    # labelsとsearch_conditionsの紐付け(1対多)
    remove_column :search_conditions, :label_id, :integer
    add_reference :search_conditions, :label, :after => :id, :null => false, index: true, foreign_key: true

    # search_conditionsとitemsの紐付け(1対多)
    remove_column :items, :label_id, :integer
    add_reference :items, :search_condition, :after => :user_id, :null => false, index: true, foreign_key: true
  end
end
