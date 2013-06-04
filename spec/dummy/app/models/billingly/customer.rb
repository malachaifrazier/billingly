# This module serves as an example on how to extend Billingly::Customer
class Billingly::Customer < Billingly::BaseCustomer
  
  def can_subscribe_to?(plan) 
    return false if plan.awesomeness_level == current_awesomeness_level && !doing_trial?
    super
  end
  
  def current_awesomeness_level
    if active_subscription && active_subscription.plan
      active_subscription.plan.awesomeness_level
    else
      nil
    end
  end
end
