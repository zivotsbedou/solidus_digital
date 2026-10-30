# frozen_string_literal: true

Spree::Core::Engine.routes.draw do
  if SolidusSupport.backend_available?
    namespace :admin do
      resources :products, only: [] do
        resources :digitals, only: [:index, :create, :destroy]
      end

      resources :orders, only: [] do
        resource :digital_links, only: [] do
          post :reset
        end
      end
    end
  end

  get "/digital/:secret", to: "digitals#show", as: :digital, constraints: {secret: /[a-zA-Z0-9]{30}/}
end
