# coding: utf-8
class ItemJob < ActiveJob::Base

  include Helper::AmazonEcs

  queue_as :default

  def perform(*args)
    user = args[0][:user]

    Label.where(user_id: user[:id]).each do |label|
      # ラベルに紐づく検索条件を取得
      label_id = label.id
      search_conditions = SearchCondition.where(label_id: label_id, seller_id: nil)

      # Amazon APIよりデータを取得
      # APIリクエスト数の最大値は、search_conditions.length * 10
      fetched_items = []
      search_conditions.each do |condition|
        max_page = condition['category'] == "All" ? 5 : 10;
        (1..max_page).each do |page|
          fetched_items.concat(req_search_api(user, condition, page))
          # Amazon APIの規約に従う
          sleep(1)
        end
      end

      # 新規商品データをdbに保存
      fetched_items.each do |fetched_item|
        item = Item.new(
          :user_id             => user[:id],
          :search_condition_id => fetched_item['search_condition_id'],
          :asin                => fetched_item['asin'],
          :code                => generate_code(fetched_item['asin'], label_id),
          :name                => fetched_item['title'].byteslice(0,255).scrub(''), # nameカラムは255byte以内
          :is_prime            => fetched_item['is_prime']
        )
        if !item.save
          next
        end
      end
    end

  end
end
