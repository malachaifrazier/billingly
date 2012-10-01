# The use cases controller in the demo app sets up all the different scenarios that we
# want to show to users.
# @note
#   All this actions depend on the first plan to have a 1.month duration.

class UseCasesController < ApplicationController
  def credit_payment
    current_customer.credit_payment(5.0)
    redirect_to subscriptions_path, notice: '$5 were credited to your account'
  end
  
  def create_new
    fresh_customer
    redirect_to subscriptions_path, notice: 'You are now a freshly signed up customer'
  end

  def create_trial
    customer = fresh_customer
    customer.subscribe_to_plan(plan, 2.days.from_now)
    redirect_to subscriptions_path,
      notice: "You are a customer on a 15 day trial period for the #{plan.name} plan"
  end
  
  def create_expired_trial
    Timecop.travel 15.days.ago
    customer = fresh_customer
    customer.subscribe_to_plan(plan, 15.days.from_now)
    Timecop.return 
    customer.deactivate_trial_expired
    redirect_to subscriptions_path,
      notice: "You are a customer whose trial period on #{plan.name} expired"
  end
  
  def create_old_user
    Timecop.travel 85.days.ago
    customer = fresh_customer
    customer.credit_payment(plan.amount * 2)
    subscription = customer.subscribe_to_plan(plan)

    # Two months go by, with the corresponding invoices
    Timecop.travel 1.month.from_now
    subscription.generate_next_invoice
    Timecop.travel 1.month.from_now
    subscription.generate_next_invoice
    Timecop.return 

    redirect_to subscriptions_path,
      notice: "You have been subscribed to #{plan.name} for 3 months."
  end
  
  def create_deactivated_debtor
    Timecop.travel 45.days.ago
    customer = fresh_customer
    customer.credit_payment(plan.amount)
    subscription = customer.subscribe_to_plan(plan)

    # Next month invoice is created
    Timecop.travel 1.month.from_now
    subscription.generate_next_invoice
    Timecop.travel subscription.grace_period.from_now
    customer.deactivate_debtor
    Timecop.return 

    redirect_to subscriptions_path,
      notice: "You have been subscribed to #{plan.name} for 45 days, you missed your last payment"
  end 

  # Selects a plan appropriate for running all this scenarios.
  def plan
    Billingly::Plan.where("periodicity = '1.month'").first
  end
end
