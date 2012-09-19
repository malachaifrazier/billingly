# This controller takes care of managing subscriptions.
class Billingly::SubscriptionsController < ::ApplicationController
  before_filter :requires_customer, only: [:index, :reactivate]
  before_filter :requires_active_customer, except: [:index, :reactivate]

  # Index shows the current subscription to customers while they are active.
  # It's also the page that prompts them to reactivate their account when deactivated.
  # It's likely the only reachable page for deactivated customers.
  def index
    @subscription = current_customer.active_subscription
    redirect_to(action: :new) unless @subscription
  end
  
  # Should let customers choose a plan to subscribe to, wheter they are subscribing
  # for the first time or upgrading their plan.
  def new
    @plans = Billingly::Plan.all
  end

  # Subscribe the customer to a plan, or change his current plan.
  def create
    plan = Billingly::Plan.find(params[:plan_id])
    current_customer.subscribe_to_plan(plan)
    on_subscription_success
  end

  # Action to reactivate an account for a customer that left voluntarily and does
  # not owe any money to us.
  # Their account will be reactivated to their old subscription plan immediately.
  # They can change plans afterwards.
  def reactivate
    return render nothing: true, status: 403 unless current_customer.reactivate
    on_reactivation_success
  end
  
  # Unsubscribes the customer from his last subscription and deactivates his account.
  # Performing this action would set the deactivation reason to be 'left_voluntarily'
  def deactivate
    current_customer.deactivate_left_voluntarily
    redirect_to(action: :index)
  end

  # When a subscription is sucessful this callback is triggered.
  # Host applications should override it by subclassing this subscriptionscontroller,
  # and include their own behaviour, and for example grant the privileges associated
  # to the subscription plan.
  def on_subscription_success
    redirect_to(action: :index) 
  end
  
  def on_reactivation_success
    on_subscription_success
  end
  
end
