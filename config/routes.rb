# frozen_string_literal: true

Rails.application.routes.draw do
  mount_devise_token_auth_for "User", at: "auth"

  resources :taxonomies
  resources :actor_categories, only: [:index, :show, :create, :destroy]
  resources :actor_measures
  resources :actors
  resources :actortype_taxonomies, only: [:index, :show]
  resources :actortypes, only: [:index, :show]
  resources :measure_actors
  resources :measure_categories
  resources :measure_indicators
  resources :measure_measures
  resources :measure_resources
  resources :measuretype_taxonomies, only: [:index, :show]
  resources :measuretypes, only: [:index, :show]
  resources :memberships, only: [:index, :show, :create, :destroy]
  resources :resourcetypes, only: [:index, :show]
  resources :user_actors
  resources :user_measures
  resources :categories
  resources :measures
  resources :indicators
  resources :users
  resources :user_roles
  resources :roles
  resources :pages
  resources :resources
  resources :bookmarks

  # public routes - separate from client API
  namespace :api do
    namespace :v1 do
      get 'public/topics', to: 'public#topics'
    end
  end

  mount LetterOpenerWeb::Engine, at: "/letter_opener" if Rails.env.development?

  root to: "static_pages#home"

end
