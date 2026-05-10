Rails.application.routes.draw do
  get "/widget.js", to: "widget#show"
  get "/widget-test", to: "widget_tests#show"
  get "/widget/agents/:public_token", to: "widget_agents#show"
  post "/widget/messages", to: "widget_messages#create"
  post "/widget/messages/stream", to: "widget_messages#stream"
  match "/widget/messages", to: "widget_messages#preflight", via: :options
  match "/widget/messages/stream", to: "widget_messages#preflight", via: :options

  resources :agents, only: [:index, :show, :new, :create, :edit, :update] do
    resources :conversations, only: [:index, :show]
    resources :knowledge_sources
  end

  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  root "agents#index"
end
