Rails.application.routes.draw do
  devise_for :users
  resources :offers, only: :index
  root to: 'pages#home'
  post "/search", to: "pages#search"
  resources :results, only:[:index] do
    get :autocomplete_city_name, :on => :collection
  end
  resources :cities, only: :index
  get "/hello", to: "hello_world#hello_world"
  get "/offers/wait", to: "offers#wait", as: "wait"
  mount Attachinary::Engine => "/attachinary"

  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
end
