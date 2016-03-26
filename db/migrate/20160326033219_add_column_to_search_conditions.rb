class AddColumnToSearchConditions < ActiveRecord::Migration
  def change
    add_column :search_conditions, :min_offer_count, :integer, default: 0, :after => :is_prime
  end
end
