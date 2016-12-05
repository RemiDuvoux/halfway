Rails.application.routes.draw do
  devise_for :users
  resources :offers, only: :index
  get 'offers/:stamp', to: 'offers#show', as: 'offer'
  root to: 'pages#home'
  resources :results, only:[:index] do
    get :autocomplete_city_name, :on => :collection
  end
  resources :cities, only: :index do
    resources :trips, only: [:create, :show]
  end
  mount Attachinary::Engine => "/attachinary"

  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
end
