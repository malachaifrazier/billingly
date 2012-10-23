require 'spec_helper'

describe Billingly::Invoice do
  let(:invoice){ create(:fourth_month).invoices.last }
  
  it 'is deemed paid when there is paid_on date' do
    invoice.should_not be_paid
    invoice.update_attribute(:paid_on, Time.now)
    invoice.should be_paid
  end
  
  describe 'when charging an invoice' do
    it 'Sets the date in which the invoice was paid' do
      Billingly::Customer.any_instance.stub(ledger: {cash: 500})
      invoice.paid_on.should be_nil
      invoice.charge.should_not be_nil
      invoice.paid_on.should_not be_nil
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
      should_add_to_journal(customer, 2) do
        invoice.charge
        extra = {invoice: invoice, subscription: invoice.subscription}
        should_have_journal_entries(customer, -(invoice.amount), :cash, extra)
        should_have_journal_entries(customer, invoice.amount, :spent, extra)
      end
    end
    
    it 'does not charge invoices if their starting period has not started yet' do
      Billingly::Customer.any_instance.stub(ledger: {cash: 500})
      invoice
      Timecop.travel invoice.period_start - 10.days
      invoice.charge.should be_nil
      invoice.should_not be_paid
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
        date = Date.today.beginning_of_year
        Timecop.travel date
        invoice = create(:first_year, subscribed_on: date).invoices.first
        Timecop.travel 6.months.from_now.to_date
        invoice.amount.should <= invoice.subscription.amount
      end
      
      pending 'from the above text, I want to assert that amount = 49.69 like so: #invoice.amount.to_f.should == 49.69'

      it 'reimburses money to the user balance if already paid' do
        date = Date.today.beginning_of_year
        Timecop.travel date
        invoice = create(:first_year, subscribed_on: date).invoices.first
        customer = invoice.customer
        customer.add_to_journal(100.0, :cash, :paid)
        Timecop.travel 1.day.from_now
        invoice.charge
        Timecop.travel 3.months.from_now.to_date
        old_cash = customer.ledger[:cash]
        should_add_to_journal(customer, 2) do
          invoice.truncate
          extra = {invoice: invoice, subscription: invoice.subscription}
          customer.reload
          customer.ledger[:cash].should > old_cash
        end
      end
      pending 'from the above example I want to test the exact cash refund being calculated'
    end
    
    describe 'when reimbursing an invoice covering a period that has not started yet' do
      it 'reimburses the whole invoice if it was paid and its start date is in the future' do
        customer = invoice.customer
        customer.add_to_journal(100.0, :cash, :paid)
        invoice.charge
        Timecop.travel 2.days.ago
        should_add_to_journal(customer, 2) do
          invoice.truncate
          extra = {invoice: invoice, subscription: invoice.subscription}
          should_have_journal_entries(customer, -99.99, :spent, extra)
          should_have_journal_entries(customer, 99.99, :cash, extra)
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
      end.not_to change{ customer.journal_entries.count }
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
    
    it 'does not notify if the customer opted out of emails' do
      Billingly::Customer.any_instance.stub(do_not_email?: true)
      should_not_email(:pending_notification)
      invoice.notify_pending
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
      Timecop.travel 15.days.from_now
      invoice.customer.credit_payment(100.0)
      invoice.reload
      should_not_email(:overdue_notification)
      invoice.notify_overdue
    end
    
    it 'does not notify if the invoice was deleted' do 
      invoice
      Timecop.travel 15.days.from_now
      invoice.update_attribute(:deleted_on, Time.now)
      should_not_email(:overdue_notification)
      invoice.notify_overdue
    end

    it 'does not notify if the customer opted out of emails' do
      invoice
      Timecop.travel 15.days.from_now
      Billingly::Customer.any_instance.stub(do_not_email?: true)
      should_not_email(:overdue_notification)
      invoice.notify_overdue
    end
  end

  describe 'when notifying paid invoices' do
    it 'notifies about the paid invoice sending the receipt too' do
      Billingly::Invoice.any_instance.stub(paid_on: 1.day.ago)
      should_email(:paid_notification)
      invoice.notify_paid
    end
    
    it 'does not notify unpaid invoices' do
      invoice
      should_not_email(:paid_notification)
      invoice.notify_paid
    end

    it 'does not notify same invoice twice' do
      Billingly::Invoice.any_instance.stub(paid_on: 1.day.ago)
      invoice.notify_paid
      should_not_email(:paid_notification)
      invoice.notify_paid
    end

    it 'does not notify if the invoice was deleted' do 
      Billingly::Invoice.any_instance.stub(paid_on: 1.day.ago)
      invoice.update_attribute(:deleted_on, Time.now)
      should_not_email(:paid_notification)
      invoice.notify_paid
    end

    it 'does not notify if the customer opted out of emails' do
      Billingly::Customer.any_instance.stub(do_not_email?: true)
      Billingly::Invoice.any_instance.stub(paid_on: 1.day.ago)
      should_not_email(:paid_notification)
      invoice.notify_paid
    end
  end
end
