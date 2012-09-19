module Billingly
  class JournalEntry < ActiveRecord::Base
    belongs_to :customer
    belongs_to :invoice
    belongs_to :payment
    belongs_to :subscription

    validates :amount, presence: true
    validates :customer, presence: true
    validates :account, presence: true, inclusion: %w(paid cash spent)
    
    attr_accessible :customer, :account, :invoice, :payment, :subscription, :amount 
    
  end
end
