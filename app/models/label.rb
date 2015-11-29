class Label < ActiveRecord::Base
  has_many :search_conditions, :dependent => :destroy

  belongs_to :user
end
