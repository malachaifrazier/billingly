# This module serves as an example on how to extend Billingly::Customer

require Billingly::Engine.model_path :customer

class Billingly::Customer
  
  def can_subscribe_to(plan) 
    plan.awesomeness_level != current_awesomeness_level
  end
  
  def current_awesomeness_level
    if active_subscription && active_subscription.plan
      active_subscription.plan.awesomeness_level
    else
      0
    end
  end
end
