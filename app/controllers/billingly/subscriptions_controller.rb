# This controller takes care of managing subscriptions.
class Billingly::SubscriptionsController < ApplicationController
  before_filter :requires_customer
  
  def new
    @plans = Billingly::Plan.all
  end

  def create
    plan = Billingly::Plan.find(params[:plan_id])
    subscription = current_customer.subscribe_to_plan(plan)
    on_subscription_success(subscription)
  end

  def requires_customer
    on_empty_customer if current_customer.nil? 
  end
  
  # This method is call on a before filter when a customer was required
  # but none was found. It's reccommended that this method redirects to
  # a login url or out of the site.
  def on_empty_customer
    redirect_to(root_path)
  end

  def on_subscription_success(subscription)
    redirect_to(:show) 
  end
end
