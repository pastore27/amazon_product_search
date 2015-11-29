# coding: utf-8
class Item < ActiveRecord::Base
  # asinカラムとuser_idの対はユニークになるように
  validates :asin, uniqueness: {
              scope: [:user_id]
            }

  belongs_to :search_condition
end
