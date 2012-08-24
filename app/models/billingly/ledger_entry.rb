module Billingly
  class LedgerEntry < ActiveRecord::Base
    belongs_to :customer
    belongs_to :invoice
    belongs_to :payment
    belongs_to :receipt
    belongs_to :subscription
    
    attr_accessible :customer, :account, :invoice, :amount 
  end
end
