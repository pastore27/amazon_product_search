# coding: utf-8
class Item < ActiveRecord::Base

  # asinカラムはユニークになるように（label_idとasinのペアがユニークになるようにする案もある。要確認）
  validates :asin, uniqueness: true

end
