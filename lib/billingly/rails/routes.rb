class ActionDispatch::Routing::Mapper
  def add_billingly_routes(skope=nil, controller='billingly/subscriptions')
    route = lambda do 
      resources :subscriptions, controller: controller do
        collection do
          post :reactivate
        end
      end
    end
    if skope then scope(skope, as: skope, &route) else route.call end
  end
end
