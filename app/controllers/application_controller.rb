# coding: utf-8
class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  def req_search_api(condition, page)
    search_word    = ''
    keyword        = condition['keyword']
    negative_match = condition['negative_match']

    keyword.split.each do |word|
      search_word << "#{word} "
    end
    negative_match.split.each do |word|
      search_word << "-#{word} "
    end

    retry_count = 0
    begin
      res = Amazon::Ecs.item_search(
        search_word,
        :search_index   => condition['category'],
        :response_group => 'Large',
        :country        => 'jp',
        :item_page      => page
      )
    rescue
      retry_count += 1
      if retry_count < 5
        sleep(5)
        retry
      else
        return false
      end
    end

    items = []
    res.items.each do |item|
      item_attributes    = item.get_element('ItemAttributes')
      item_offer_listing = item.get_element('Offers/Offer/OfferListing')

      items.push({
                   'asin'     => item.get('ASIN'),
                   'jan'      => item_attributes.get('EAN'),
                   'title'    => item_attributes.get('Title'),
                   'url'      => item.get('DetailPageURL'),
                   'price'    => item_attributes.get('ListPrice/Amount'),
                   'headline' => item_attributes.get('Brand'),
                   'features' => item_attributes.get_array('Feature'),
                   # item.get_element('Offers/Offer/OfferListing') が取得できないことがある。
                   'is_prime' => item_offer_listing ? item_offer_listing.get('IsEligibleForPrime') : 0
                 })
    end

    return res, items
  end

end
