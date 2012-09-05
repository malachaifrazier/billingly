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
    
    def deleted?
      not deleted_on.nil?
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
      customer.add_to_ledger(amount, :spent, extra)

      save! # save receipt
      return receipt
    end
    
    # When a subscription terminates, it's last invoice gets truncated so that it does
    # not extend beyond the duration of the subscription.
    def truncate
      return if Time.now > self.period_end
      old_amount = self.amount
      new_amount = if self.period_start < Time.now 
        whole_period = self.period_end - self.period_start
        used_period = Time.now - self.period_start
        self.period_end = Time.now
        used_period.round * old_amount / whole_period.round
      else
        self.deleted_on = Time.now
        0
      end
      self.amount = BigDecimal.new(new_amount.round(2).to_s)
      if paid?
        reimburse = (old_amount - self.amount).round(2)
        extra = {invoice: self, subscription: subscription}
        customer.add_to_ledger(reimburse, :cash, extra)
        customer.add_to_ledger(-(reimburse), :spent, extra)
      end
      save!
      self.charge
      return self
    end

    # Charges all invoices that can be charged from the existing customer cash balances
    def self.charge_all(collection = self)
      collection.where(deleted_on: nil, receipt_id: nil).order('period_start').each do |invoice|
        invoice.charge
      end
    end
    
    # Send the email notifying that this invoice is due soon and should be paid.
    def self.notify_all_pending
      where('due_on < ?', Billingly::Subscription::GRACE_PERIOD.from_now)
        .where(deleted_on: nil, receipt_id: nil, notified_pending_on: nil)
        .each do |invoice|
          invoice.notify_pending
        end
    end

    def notify_pending
      return unless notified_pending_on.nil?
      return if paid?
      return if deleted?
      return if due_on > Billingly::Subscription::GRACE_PERIOD.from_now
      BillinglyMailer.pending_notification(self).deliver!
      update_attribute(:notified_pending_on, Time.now)
    end

    # Send the email notifying that this invoice being overdue and the subscription
    # being cancelled
    def self.notify_all_overdue
      where('due_on <= ?', Time.now)
        .where(deleted_on: nil, receipt_id: nil, notified_overdue_on: nil)
        .each do |invoice|
          invoice.notify_overdue
        end
    end

    def notify_overdue
      return unless notified_overdue_on.nil?
      return if paid?
      return if deleted?
      return if due_on > Time.now
      BillinglyMailer.overdue_notification(self).deliver!
      update_attribute(:notified_overdue_on, Time.now)
    end

    # Notifies that the invoice has been charged successfully.
    # Send the email notifying that this invoice being overdue and the subscription
    # being cancelled
    def self.notify_all_paid
      where('receipt_id is not null')
        .where(deleted_on: nil, notified_paid_on: nil).each do |invoice|
          invoice.notify_paid
        end
    end
    def notify_paid
      return unless paid?
      return unless notified_paid_on.nil?
      return if deleted?
      BillinglyMailer.paid_notification(self).deliver!
      update_attribute(:notified_paid_on, Time.now)
    end
  end
end
