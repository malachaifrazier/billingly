# Processes payments
module Billingly
  class Payment < ActiveRecord::Base
    belongs_to :customer
    has_many :ledger_entries
    attr_accessible :amount, :customer
    
    # Process a new payment done by a customer.
    # Payments can be credited at any point and they are bound to increase
    # a customer's balance. Payments are not mapped 1 to 1 with invoices,
    # instead, invoices are deemed as paid whenever the customer's balance
    # is enough to cover them.
    def self.credit_for(customer, amount) 
      create!(amount: amount, customer: customer).tap do |payment|
        customer.add_to_journal(amount, :cash, :paid, payment: payment)
      end
    end
  end
end
