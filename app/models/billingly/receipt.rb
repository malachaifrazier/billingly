module Billingly
  class Receipt < ActiveRecord::Base
    belongs_to :customer
    has_one :invoice
    has_many :ledger_entries

    attr_accessible :customer, :paid_on
  end
end
