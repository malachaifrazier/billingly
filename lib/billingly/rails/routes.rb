class ActionDispatch::Routing::Mapper
  def add_billingly_routes(skope=nil, controller='billingly/subscriptions')
    route = lambda do 
      resources :subscriptions, controller: controller, only: [:index, :create] do
        collection do
          match 'invoice/:invoice_id' => :invoice, as: :invoice
          post :reactivate
          post :deactivate
        end
      end
      resources :redemptions, controller: 'billingly/redemptions', only: [:new, :create]
      get 'redeem' => "billingly/redemptions#new"
    end
    if skope then scope(skope, as: skope, &route) else route.call end
  end
end
