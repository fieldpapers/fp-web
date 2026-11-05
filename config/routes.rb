Rails.application.routes.draw do
  devise_for :users, controllers: { sessions: "users/sessions", passwords: "users/passwords", omniauth_callbacks: "users/omniauth_callbacks" }

  resource :account, only: [:show, :destroy] do
    post :merge
  end

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

  resources :atlases, only: [:index, :show], :concerns => :pageable do
    resources :snapshots, only: [:index]
    member do
      get ':page_number' => 'pages#show',
        as: :atlas_page,
        constraints: {
          id: /(?:(?!page).)+/ # use negative lookaheads to match anything
                               # *except* page (necessary because concerns
                               # are prioritized lower)
        }
    end
  end

  post '/locale' => 'locales#update', as: :change_locale

  get '/compose' => 'compose#new', as: :compose
  post '/compose' => 'compose#create'
  put '/compose' => 'compose#update'

  resources :snapshots, only: [:index, :show, :new, :create], :concerns => :pageable

  mount Rack::NotFound.new("public/404.html") => "activity.php"
end
