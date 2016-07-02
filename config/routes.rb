Rails.application.routes.draw do

  root 'home#index'

  post '/login' => 'home#login', as: :login

  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
end
