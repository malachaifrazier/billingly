Billingly::Engine.routes.draw do
  resource :subscriptions, only: [:new, :create]
end
