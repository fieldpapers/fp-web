Rails.application.routes.draw do
  devise_for :users

  # The priority is based upon order of creation: first created -> highest priority.
  # See how all your routes lay out with "rake routes".

  # site root
  root 'home#index'

  get '/advanced' => 'home#advanced', as: :advanced
  get '/make-canned-atlas-template' => 'home#make-canned-atlas-template', as: :make_canned_atlas
  get '/make-geojson-atlas-form' => 'home#make-geojson-atlas-form', as: :make_geojson_atlas
  get '/upload-mbtiles' => 'home#upload-mbtiles', as: :upload_mbtiles

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

  # URL backward-compatibility

  get 'atlas.php' => 'atlases#show', redirect: true
  get 'atlases.php' => 'atlases#index', redirect: true
  get 'snapshot.php' => 'snapshots#show', redirect: true
  get 'snapshots.php' => 'snapshots#index', redirect: true
end
