Rails.application.routes.draw do

  root to: "labels#index"

  devise_for :users, :controllers => {
               :registrations => 'users/registrations',
               :passwords     => 'users/passwords'
             }
  resources :users, :only => [:index]
  get  "/users/:user_id/update_memo" => "users#update_memo_form"
  post "/users/:user_id/update_memo" => "users#update_memo"

  get  "/search_products"          => "search_products#index"
  post "/search_products/products" => "search_products#get_products"
  post "/search_products/create"   => "search_products#create_search_condition"

  get  "/search_products_by_seller_id"          => "search_products#form_for_search_by_seller_id"
  post "/search_products_by_seller_id/products" => "search_products#get_products_by_asins"
  post "/search_products_by_seller_id/create"   => "search_products#create_label_and_search_condition"

  get  "/labels"                                => "labels#index"
  get  "/labels/index_for_seller_id"            => "labels#index_for_seller_id"
  get  "/labels/new"                            => "labels#create_form"
  post "/labels/create"                         => "labels#create"
  get  "/labels/:user_id/:id/update"            => "labels#update_form"
  post "/labels/:user_id/:id/update"            => "labels#update"
  get  "/labels/:user_id/:id/delete"            => "labels#delete"
  get  "/labels/:user_id/:id/search_conditions" => "labels#search_conditions"
  get  "/labels/:user_id/:id/search_conditions/:search_condition_id/delete" => "labels#delete_search_condition"
  get  "/labels/:user_id/:label_id/items"                 => "items#index"
  post "/labels/:user_id/:label_id/add_items"             => "items#add_items"
  post "/labels/:user_id/:label_id/add_items_by_asins"    => "items#add_items_by_asins"
  post "/labels/:user_id/:label_id/download_items"        => "items#download_items"
  post "/labels/:user_id/:label_id/:page/download_imgs"   => "items#download_imgs"
  post "/labels/:user_id/:label_id/check_items"           => "items#check_items"
  get  "/labels/:user_id/:label_id/items/:item_id/delete" => "items#delete"
  post "/labels/:user_id/:label_id/delete_items"          => "items#delete_items"

  get  "/prohibited_words"            => "prohibited_words#index"
  get  "/prohibited_words/new"        => "prohibited_words#create_form"
  post "/prohibited_words/create"     => "prohibited_words#create"
  get  "/prohibited_words/:id/delete" => "prohibited_words#delete"

  get  "/bulks"                                => "bulks#index"
  post "/bulks/:user_id/add_search_conditions" => "bulks#add_search_conditions"
  post "/bulks/:user_id/add_items"             => "bulks#add_items"
  post "/bulks/:user_id/check_items"           => "bulks#check_items"
  post "/bulks/:user_id/delete_items"          => "bulks#delete_items"

  get  "/accounts"                 => "accounts#index"
  get  "/accounts/:user_id/update" => "accounts#update_form"
  post "/accounts/:user_id/update" => "accounts#update"

  # The priority is based upon order of creation: first created -> highest priority.
  # See how all your routes lay out with "rake routes".

  # You can have the root of your site routed with "root"
  # root 'welcome#index'

  # Example of regular route:
  #   get 'products/:id' => 'catalog#view'

  # Example of named route that can be invoked with purchase_url(id: product.id)
  #   get 'products/:id/purchase' => 'catalog#purchase', as: :purchase

  # Example resource route (maps HTTP verbs to controller actions automatically):
  #   resources :products

  # Example resource route with options:
  #   resources :products do
  #     member do
  #       get 'short'
  #       post 'toggle'
  #     end
  #
  #     collection do
  #       get 'sold'
  #     end
  #   end

  # Example resource route with sub-resources:
  #   resources :products do
  #     resources :comments, :sales
  #     resource :seller
  #   end

  # Example resource route with more complex sub-resources:
  #   resources :products do
  #     resources :comments
  #     resources :sales do
  #       get 'recent', on: :collection
  #     end
  #   end

  # Example resource route with concerns:
  #   concern :toggleable do
  #     post 'toggle'
  #   end
  #   resources :posts, concerns: :toggleable
  #   resources :photos, concerns: :toggleable

  # Example resource route within a namespace:
  #   namespace :admin do
  #     # Directs /admin/products/* to Admin::ProductsController
  #     # (app/controllers/admin/products_controller.rb)
  #     resources :products
  #   end
end
