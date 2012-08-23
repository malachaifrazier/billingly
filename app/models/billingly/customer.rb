# A Customer is the main entity of Billingly:
#   * Customers are subscribed to plans
#   * Customers are charged for one-time expenses.
#   * Payments are received on a Customer's behalf and credited to their account.
#   * Invoices are generated periodically calculating charges a Customer incurred in.
#   * Receipts are sent to Customers when their invoices are paid.

module Billingly
  class Customer < ActiveRecord::Base
    has_many :subscriptions
    has_many :one_time_charges
    has_many :invoices

    # Customers can be subscribed to one or more services. While subscribed, Customers
    # will pay recurring charges for using the given service.
    # Every customer can potentially get a special deal, but we also offer common
    # deals as 'plans' from which a proper subscription is created.
    def subscribe_to_plan(plan) 
      old = subscriptions.last

      subscriptions.build.tap do |new|
        [:payable_upfront, :description, :length, :amount].each do |k|
          new[k] = plan[k]
        end
        new.subscribed_on = DateTime.now
        new.save!
        old.update_attribute(:unsubscribed_on, new.subscribed_on) if old
      end
    end
    
    # We can schedule one-time charges for a user using this short-hand method.
    # The charge_on date is the date in which you expect the invoicing script
    # to pick up and inform the charge. You can't schedule one-time charges
    # for periods that have already been invoiced.
    def schedule_one_time_charge(charge_on, amount, description)
      return if charge_on < 1.day.from_now
      one_time_charges.create!(
        charge_on: charge_on, amount: amount, description: description)
    end
  
    # When call generates an invoice from the last invoice generates or in case of
    # the first invoice since the customer became a customer.
    def generate_invoice  
      # Check if I should be generating an invoice already.
      # Invoices should be created if their due_on is less than 15 days away.
      active = active_subscription
      period_start = if active.invoices.empty?    
        active.invoices.last.period_end 
      else
        active.subscribed_on
      end
      
      period_end = period_start + 1.month
      
      due_on = (active.payable_upfront ? period_start : period_end) +
        Invoice.default_grace_period
    end
    
    # Returns the actual subscription of the customer. while working with the 
    # customer API a customer should only have 1 active subscription at a time.
    def active_subscription
      subscriptions.last
    end 
  end
end
