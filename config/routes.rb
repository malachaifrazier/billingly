Billingly::Engine.routes.draw do
  resource :subscriptions, only: [:show]
end
