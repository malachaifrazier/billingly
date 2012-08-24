module Billingly
  class Invoice < ActiveRecord::Base
    belongs_to :subscription
    belongs_to :customer
    belongs_to :receipt
    has_many :ledger_entries 
    attr_accessible :customer, :amount, :due_on, :period_start, :period_end
  end
end
