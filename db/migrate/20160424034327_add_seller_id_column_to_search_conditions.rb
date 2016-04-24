class AddSellerIdColumnToSearchConditions < ActiveRecord::Migration
  def change
    add_column :search_conditions, :seller_id, :string, :after => :min_offer_count
  end
end
