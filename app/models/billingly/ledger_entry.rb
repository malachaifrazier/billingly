module Billingly
  class LedgerEntry < ActiveRecord::Base
    belongs_to :customer
    belongs_to :invoice
    belongs_to :payment
    belongs_to :receipt
    belongs_to :subscription

    validates :account, presence: true
    
    attr_accessible :customer, :account, :invoice, :payment, :receipt, :subscription, :amount 
    
  end
end
