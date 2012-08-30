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
    
    # Settle an invoice by moving money from the cash balance into an expense,
    # generating a receipt and marking the invoice as paid.
    def charge
      return if paid?
      return unless deleted_on.nil?
      return if customer.ledger[:cash] < amount

      receipt = create_receipt!(customer: customer, paid_on: Time.now)
      extra = {receipt: receipt, subscription: subscription}
      customer.add_to_ledger(-(amount), :cash, extra)
      customer.add_to_ledger(amount, :expenses, extra)

      save! # save receipt
      return receipt
    end
    
    # When a subscription terminates, it's last invoice gets truncated so that it does
    # not extend beyond the duration of the subscription.
    def truncate
      return if Time.now > self.period_end
      self.period_end = Time.now
      old_amount = self.amount
      self.amount = BigDecimal.new((amount.to_f / 2).round(2).to_s)
      if paid?
        reimburse = (old_amount - self.amount).round(2)
        extra = {invoice: self, subscription: subscription}
        customer.add_to_ledger(reimburse, :cash, extra)
        customer.add_to_ledger(-(reimburse), :expenses, extra)
      end
      save!
      self.charge
      return self
    end

    # Charges all invoices that can be charged from the existing customer cash balances
    def self.charge_all
      where(deleted_on: nil, receipt_id: nil).order('period_start').each do |invoice|
        invoice.charge
      end
    end
    
  end
end
