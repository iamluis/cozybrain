Rails.application.routes.draw do
  resource :session
  resources :passwords, param: :token
  resources :receipts, only: [ :new, :create, :show, :edit, :update ]
  resources :invoices, only: [ :index, :show, :create, :update ] do
    member { post :send_to_client }
  end
  resource :home,  only: :show
  resource :pulse, only: :show, controller: :weekly_pulses
  post "tray/inbound_docs/:filing_id/classify", to: "tray#classify", as: :tray_classify

  # Bank-tx ↔ Filing matching. `new` shows the candidate receipts;
  # `create` actually links them.
  namespace :ledger do
    resources :matches, only: [ :new, :create ]
    resources :dismissals, only: :create
  end
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  root "pages#home"
end
