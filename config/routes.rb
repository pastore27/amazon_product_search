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

  get  "/labels"                                => "labels#index"
  get  "/labels/new"                            => "labels#create_form"
  post "/labels/create"                         => "labels#create"
  get  "/labels/:user_id/:id/update"            => "labels#update_form"
  post "/labels/:user_id/:id/update"            => "labels#update"
  get  "/labels/:user_id/:id/delete"            => "labels#delete"
  get  "/labels/:user_id/:id/search_conditions" => "labels#search_conditions"
  get  "/labels/:user_id/:id/search_conditions/:search_condition_id/delete" => "labels#delete_search_condition"
  get  "/labels/:user_id/:label_id/items"                 => "items#index"
  post "/labels/:user_id/:label_id/add_items"             => "items#add_items"
  post "/labels/:user_id/:label_id/download_items"        => "items#download_items"
  post "/labels/:user_id/:label_id/:page/download_imgs"   => "items#download_imgs"
  post "/labels/:user_id/:label_id/check_stock"           => "items#check_stock"
  get  "/labels/:user_id/:label_id/items/:item_id/delete" => "items#delete"

  get  "/prohibited_words"            => "prohibited_words#index"
  get  "/prohibited_words/new"        => "prohibited_words#create_form"
  post "/prohibited_words/create"     => "prohibited_words#create"
  get  "/prohibited_words/:id/delete" => "prohibited_words#delete"

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
