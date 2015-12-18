require 'api_constraints'

Rails.application.routes.draw do
  devise_for :users

  # The priority is based upon order of creation: first created -> highest priority.
  # See how all your routes lay out with "rake routes".

  # site root
  root 'home#index'

  get '/about' => 'home#about', as: :about
  get '/advanced' => 'home#advanced', as: :advanced
  get '/make-canned-atlas-template' => 'home#make-canned-atlas-template', as: :make_canned_atlas
  get '/make-geojson-atlas-form' => 'home#make-geojson-atlas-form', as: :make_geojson_atlas

  concern :pageable do
    get '(page/:page)' => :index, on: :collection, as: ''
  end

  resources :atlases, :concerns => :pageable do
    member do
      get ':page_number' => 'pages#show',
        as: :atlas_page,
        constraints: {
          id: /(?:(?!page).)+/ # use negative lookaheads to match anything
                               # *except* page (necessary because concerns
                               # are prioritized lower)
        }
      patch ':page_number' => 'pages#update',
        constraints: {
          id: /(?:(?!page).)+/ # use negative lookaheads to match anything
                               # *except* page (necessary because concerns
                               # are prioritized lower)
        }
    end
  end

  resources :compose
  resources :snapshots, :concerns => :pageable

  mount Rack::NotFound.new("public/404.html") => "activity.php"

  # API routes: versioned, no HTML rendering
  namespace :api, defaults: { format: 'json' } do
    scope module: :v1, constraints: ApiConstraints.new(version: 1, default: true) do
      resources :atlases, except: [:new, :edit]
      get '/atlases/:id/page/:page_number' => 'atlases#page'
      get '/atlases/:id/status'            => 'atlases#status'
      resources :snapshots, except: [:new, :edit]
      get '/snapshots/:id/status'          => 'snapshots#status'
      get '/s3_upload/:filename'           => 's3_upload#show'
    end
  end
end
