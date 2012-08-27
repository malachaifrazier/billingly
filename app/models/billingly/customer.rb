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
    has_many :ledger_entries
    
    attr_accessible :customer_since

    # Customers subscribe to the service and perform periodic payments to continue using it.
    # We offer common plans stating how much and how often they should pay, also, if the
    # payment is to be done at the beginning or end of the period (upfront or due-month)
    # Every customer can potentially get a special deal, but we offer common
    # deals as 'plans' from which a proper subscription is created.
    def subscribe_to_plan(plan) 
      old = subscriptions.last

      subscriptions.build.tap do |new|
        [:payable_upfront, :description, :periodicity, :amount].each do |k|
          new[k] = plan[k]
        end
        new.subscribed_on = Time.now
        new.save!
        old.update_attribute(:unsubscribed_on, new.subscribed_on) if old
        new.generate_next_invoice  
      end
    end
    
    # Returns the actual subscription of the customer. while working with the 
    # customer API a customer should only have 1 active subscription at a time.
    def active_subscription
      subscriptions.last
    end 
    
    # Every transaction is registered in the journal from where a general ledger can
    # be retrieved.
    # Due to silly rounding errors on sqlite we need to convert decimals to float and then to
    # decimals again. :S
    def ledger
      ({}).tap do |all|
        ledger_entries.group_by(&:account).collect do |account, entries|
          all[account.to_sym] = entries.collect(&:amount).collect(&:to_f).inject(0.0) do |sum,item|
            (BigDecimal.new(sum.to_s) + BigDecimal.new(item.to_s)).to_f
          end
        end
      end
    end
    
    # Credits a payment for a customer, settling invoices if possible.
    def credit_payment(amount)
      Billingly::Payment.credit_for(self, amount)
      pending = invoices.where(receipt_id: nil).order('period_start ASC').first
      pending.settle unless pending.nil?
    end
  end
end
