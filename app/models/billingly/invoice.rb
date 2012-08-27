module Billingly
  class Invoice < ActiveRecord::Base
    belongs_to :subscription
    belongs_to :customer
    belongs_to :receipt
    has_many :ledger_entries 
    attr_accessible :customer, :amount, :due_on, :period_start, :period_end
    
    def paid?
      not receipt.nil?
    end
    
    def acknowledged_expense?
      not acknowledged_expense.nil?
    end
    
    # As customers increase their balance with payments, we check if their balance
    # is enough to cover the amount of a given invoice and pay for it.
    def settle
      return if paid?
      return if customer.ledger[:cash] < amount
      receipt = self.create_receipt!(customer: customer, paid_on: Time.now)
      if subscription.payable_upfront?
        %w(ioweyou cash services_to_provide).each do |account|
          receipt.ledger_entries.create!(account: account, customer: customer,
            subscription: subscription, amount: -(amount))
        end
        receipt.ledger_entries.create!(account: 'paid_upfront', customer: customer,
          subscription: subscription, amount: amount)
      else
        %w(debt cash).each do |account|
          receipt.ledger_entries.create!(account: account, customer: customer,
            subscription: subscription, amount: -(amount))
        end
      end
      save!
      return receipt
    end
    
    # Upfront payments are credited to the: paid_upfront account, instead of
    # going to the regular 'cash' balance. This way we can separate the money
    # we could potentially refund from the money we actually spent servicing them.
    def acknowledge_expense
      return if Time.now < period_end
      return unless paid?
      return unless subscription.payable_upfront
      return if acknowledged_expense?
      ledger_entries.create!(account: 'paid_upfront', customer: customer,
        subscription: subscription, amount: -(amount))
      ledger_entries.create!(account: 'expenses', customer: customer,
        subscription: subscription, amount: amount)
      update_attribute(:acknowledged_expense, Time.now)
    end

    # This class method is called from a cron job, it acknowledges all the expenses for
    # invoices that have already been paid.
    def self.acknowledge_expenses
      where(acknowledged_expense: nil).each {|invoice| invoice.acknowledge_expense }
    end
  end
end
