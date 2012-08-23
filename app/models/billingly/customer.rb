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

    # Customers can be subscribed to one or more services. While subscribed, Customers
    # will pay recurring charges for using the given service.
    # Every customer can potentially get a special deal, but we also offer common
    # deals as 'plans' from which a proper subscription is created.
    def subscribe_to_plan(plan) 
      sub = subscriptions.build.tap do |s|
        [:payable_upfront, :description, :length, :amount].each do |k|
          s[k] = plan[k]
        end
        s.subscribed_on = DateTime.now
        s.save!
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
  end
end
