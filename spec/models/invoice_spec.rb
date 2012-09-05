require 'spec_helper'

describe Billingly::Invoice do
  let(:invoice){ create(:fourth_month).invoices.last }
  
  it 'is deemed paid when there is a receipt associated to it' do
    invoice.should_not be_paid
    invoice.create_receipt(customer: invoice.customer, paid_on: Time.now)
    invoice.should be_paid
  end
  
  describe 'when charging an invoice' do
    it 'generates a receipt' do
      Billingly::Customer.any_instance.stub(ledger: {cash: 500})
      invoice.receipt.should be_nil
      invoice.charge.should_not be_nil
      invoice.receipt.should_not be_nil
    end
    
    it 'does not attempt to charge if already charged' do
      Billingly::Customer.any_instance.stub(ledger: {cash: 500})
      invoice.charge
      invoice.should be_paid
      invoice.charge.should be_nil
    end
    
    it 'does not attempt to charge deleted invoices' do
      invoice.update_attribute(:deleted_on, Time.now)
      invoice.charge.should be_nil
      invoice.should_not be_paid
    end

    it 'does not charge if customer cash balance is not enough' do
      Billingly::Customer.any_instance.stub(ledger: {cash: 0})
      invoice.charge.should be_nil
      invoice.should_not be_paid
    end

    it 'increases expenses and reduces the cash balance when charging' do
      Billingly::Customer.any_instance.stub(ledger: {cash: 200})
      customer = invoice.customer
      should_add_to_ledger(customer, 2) do
        receipt = invoice.charge
        extra = {receipt: receipt, subscription: invoice.subscription}
        should_have_ledger_entries(customer, -(invoice.amount), :cash, extra)
        should_have_ledger_entries(customer, invoice.amount, :spent, extra)
      end
    end
    
    it 'does not charge invoices if their starting period has not started yet' do
    end

  end
  
  describe 'when truncating an invoice' do
    let(:invoice){ create(:first_year).invoices.first }

    describe 'when reimbursing the current invoice' do
      it 'changes the end of the period covered' do
        invoice.truncate
        invoice.period_end.utc.to_s.should == Time.now.utc.to_s
      end

      it 'prorates and changes its price' do
        Timecop.travel 6.months.from_now.to_date
        invoice.truncate
        invoice.amount.to_f.should == 49.55
      end

      it 'reimburses money to the user balance if already paid' do
        Timecop.travel Date.today
        customer = invoice.customer
        customer.add_to_ledger(100.0, :cash, :paid)
        receipt = invoice.charge
        Timecop.travel 3.months.from_now.to_date
        should_add_to_ledger(customer, 2) do
          invoice.truncate
          extra = {invoice: invoice, subscription: invoice.subscription}
          should_have_ledger_entries(customer, -75.1, :spent, extra)
          should_have_ledger_entries(customer, 75.1, :cash, extra)
        end
      end
    end
    
    describe 'when reimbursing an invoice covering a period that has not started yet' do
      it 'reimburses the whole invoice if it was paid and its start date is in the future' do
        customer = invoice.customer
        customer.add_to_ledger(100.0, :cash, :paid)
        receipt = invoice.charge
        Timecop.travel 2.days.ago
        should_add_to_ledger(customer, 2) do
          invoice.truncate
          extra = {invoice: invoice, subscription: invoice.subscription}
          should_have_ledger_entries(customer, -99.99, :spent, extra)
          should_have_ledger_entries(customer, 99.99, :cash, extra)
        end
      end
      it 'makes the amount 0 dollars' do
        Timecop.travel 2.days.ago
        invoice.truncate
        invoice.amount.to_f.should == 0
        invoice.should be_deleted
      end
    end
    
    it 'does not reimburse anything if unpaid' do
      customer = invoice.customer
      Timecop.travel 6.months.from_now
      expect do
        invoice.truncate
        customer.reload
      end.not_to change{ customer.ledger_entries.count }
    end
    
    it 'charges the new amount, will fail if already paid' do
      Billingly::Invoice.any_instance.should_receive(:charge)
      invoice.truncate
    end
    
    it 'does not truncate invoice that cover periods that already ended' do
      Timecop.travel 2.years.from_now
      invoice.truncate.should be_nil
    end
  end

  describe 'batch charging invoices' do
    it 'should charge all unpaid invoices' do
      Billingly::Customer.any_instance.stub(ledger: {cash: 300})
      3.times{ create(:first_month, customer: create(:customer)) }
      Billingly::Invoice.first.charge

      expect do
        Billingly::Invoice.charge_all
      end.to change{ Billingly::Invoice.where(receipt_id: nil).count }.by(-2)
    end
    
    it 'should charge all unpaid invoices for a specific customer' do
      Billingly::Customer.any_instance.stub(ledger: {cash: 300})
      3.times{ create(:first_month, customer: create(:customer)) }

      expect do
        Billingly::Invoice.charge_all(Billingly::Customer.first.invoices)
      end.to change{ Billingly::Invoice.where(receipt_id: nil).count }.by(-1)
    end
    
    it 'should not settle invoice if customer does not have enough money in balance' do
      create(:first_month)
      expect do
        Billingly::Invoice.charge_all
      end.not_to change{ Billingly::Invoice.where(receipt_id: nil).count }
    end
    
    it 'should settle oldest invoice first' do
      subscription = create(:first_month)
      Timecop.travel 1.month.from_now
      oldest = subscription.invoices.first
      latest = subscription.generate_next_invoice

      # We credit the customer balance after creating the second invoice, because
      # 'generate_next_invoice' will charge it immediately otherwise.
      subscription.customer.add_to_ledger(10, :cash)
  
      Billingly::Invoice.charge_all
      oldest.reload
      oldest.should be_paid

      latest.reload
      latest.should_not be_paid
    end
  end
  
  describe 'when notifying pending invoices' do
    it 'notifies about unpaid invoices at the start of their grace period' do
      invoice
      should_email(:pending_notification)
      invoice.notify_pending
    end
    
    it 'does not notify if they are not in their grace period yet' do
      invoice
      Timecop.travel 10.days.ago
      should_not_email(:pending_notification)
      invoice.notify_pending
    end
    
    it 'does not notify twice' do
      invoice
      invoice.notify_pending
      should_not_email(:pending_notification)
      invoice.notify_pending
    end
    
    it 'does not notify if invoice was paid' do
      invoice
      invoice.customer.credit_payment(100.0)
      invoice.reload
      should_not_email(:pending_notification)
      invoice.notify_pending
    end
    
    it 'does not notify if the invoice was deleted' do
      invoice.update_attribute(:deleted_on, Time.now)
      should_not_email(:pending_notification)
      invoice.notify_pending
    end
    
    it 'notifies all pending invoices' do
      create(:first_month) # This one is not due until a month from now
      invoice = create(:first_year).invoices.last # This one should be invoiced as it is due soon
      expect do
        Billingly::Invoice.notify_all_pending
      end.to change{ ActionMailer::Base.deliveries.count }.by(1)
      invoice.reload
      invoice.notified_pending_on.should_not be_nil
      Billingly::Invoice
        .where(receipt_id: nil, notified_pending_on: nil)
        .where('due_on < ?', 20.days.from_now).count.should == 0
    end
  end

  describe 'when notifying overdue invoices' do
    it 'notifies the debtor about his account being disabled' do
      invoice
      Timecop.travel 15.days.from_now
      should_email(:overdue_notification)
      invoice.notify_overdue
    end
    
    it 'does not notify non-overdue invoices' do
      invoice
      should_not_email(:overdue_notification)
      invoice.notify_overdue
    end
    
    it 'does not notify about the same overdue invoice twice' do
      invoice
      Timecop.travel 15.days.from_now
      invoice.notify_overdue
      should_not_email(:overdue_notification)
      invoice.notify_overdue
    end
    
    it 'does not notify if invoice was paid' do
      invoice
      invoice.customer.credit_payment(100.0)
      invoice.reload
      should_not_email(:overdue_notification)
      invoice.notify_overdue
    end
    
    it 'does not notify if the invoice was deleted' do 
      invoice.update_attribute(:deleted_on, Time.now)
      should_not_email(:overdue_notification)
      invoice.notify_overdue
    end

    it 'notifies all overdue invoices' do
      create(:first_month) # This one is not due until a month from now
      invoice = create(:first_year).invoices.last # This one should be invoiced as it is due soon
      Timecop.travel 20.days.from_now
      expect do
        Billingly::Invoice.notify_all_overdue
      end.to change{ ActionMailer::Base.deliveries.count }.by(1)
      invoice.reload
      invoice.notified_overdue_on.should_not be_nil
      Billingly::Invoice
        .where(receipt_id: nil, notified_overdue_on: nil)
        .where('due_on < ?', Time.now).count.should == 0
    end
  end

  describe 'when notifying paid invoices' do
    it 'notifies about the paid invoice sending the receipt too' do
      invoice
      invoice.customer.credit_payment(100.0)
      invoice.reload
      should_email(:paid_notification)
      invoice.notify_paid
    end
    
    it 'does not notify unpaid invoices' do
      invoice
      should_not_email(:paid_notification)
      invoice.notify_paid
    end

    it 'does not notify same invoice twice' do
      invoice
      invoice.notify_paid
      should_not_email(:paid_notification)
      invoice.notify_paid
    end

    it 'does not notify if the invoice was deleted' do 
      invoice.update_attribute(:deleted_on, Time.now)
      should_not_email(:paid_notification)
      invoice.notify_paid
    end

    it 'notifies all paid invoices' do
      invoice = create(:first_year).invoices.first # This one should be paid
      create(:first_year, customer: create(:customer)) 
      invoice.customer.credit_payment(100.0)
      expect do
        Billingly::Invoice.notify_all_paid
      end.to change{ ActionMailer::Base.deliveries.count }.by(1)
      invoice.reload
      invoice.notified_paid_on.should_not be_nil
      Billingly::Invoice
        .where('receipt_id IS NOT NULL AND notified_paid_on IS NULL').count.should == 0
    end
  end
end
