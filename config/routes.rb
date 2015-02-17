Rails.application.routes.draw do
  devise_for :users

  # The priority is based upon order of creation: first created -> highest priority.
  # See how all your routes lay out with "rake routes".

  # site root
  root 'home#index'

  get '/advanced' => 'home#advanced', as: :advanced

  concern :pageable do
    get '(page/:page)' => :index, on: :collection, as: ''
  end

  resources :atlases, :concerns => :pageable do
    member do
      get ':page',
        action: :show_page,
        as: :atlas_page,
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
