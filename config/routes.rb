Rails.application.routes.draw do

  devise_for :users, :controllers => {
               :registrations => 'users/registrations'
             }
  root to: "labels#show"

  get  "/search_products"          => "search_products#show"
  post "/search_products/products" => "search_products#get_products"
  post "/search_products/create"   => "search_products#create_search_condition"

  get  "/export_products"     => "export_products#show"
  post "/export_products/csv" => "export_products#download", format: "csv"

  get  "/labels"                                  => "labels#show"
  get  "/labels/new"                              => "labels#create_form"
  post "/labels/create"                           => "labels#create"
  get  "/labels/:user_id/:id/update"              => "labels#update_form"
  post "/labels/:user_id/:id/update"              => "labels#update"
  get  "/labels/:user_id/:id/delete"              => "labels#delete"
  get  "/labels/:user_id/:id/search_conditions"   => "labels#search_conditions"
  get  "/labels/:user_id/:id/items"               => "items#show"
  post "/labels/:user_id/:id/add_items"           => "items#add_items"
  post "/labels/:user_id/:id/download_items"      => "items#download_items"
  post "/labels/:user_id/:id/:page/download_imgs" => "items#download_imgs"
  post "/labels/:user_id/:id/check_stock"         => "items#check_stock"
  get  "/labels/:user_id/:id/search_condition/:search_condition_id/delete" => "labels#delete_search_condition"

  get  "/prohibited_words"            => "prohibited_words#show"
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
