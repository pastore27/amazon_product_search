class SearchCondition < ActiveRecord::Base
  has_many :items, :dependent => :destroy

  belongs_to :label
end
