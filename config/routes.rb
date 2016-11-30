Rails.application.routes.draw do
  devise_for :users
  root to: 'pages#home'
  post "/search", to: "pages#search"
  resources :results, only:[:index] do
    get :autocomplete_airport_name, :on => :collection
  end
  resources :cities, only: :index
  mount Attachinary::Engine => "/attachinary"

  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
end
