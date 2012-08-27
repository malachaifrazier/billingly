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
      payment = create!(amount: amount, customer: customer)
      %w(cash income).each do |account|
        customer.ledger_entries.create!(customer: customer, account:account,
          payment: payment, amount: amount)
      end
      return payment
    end
  end
end
