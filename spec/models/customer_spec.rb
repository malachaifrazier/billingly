require 'spec_helper'

describe Billingly::Customer do
  let(:plan){ build(:pro_50_monthly) }
  let(:customer){ create(:customer) }
  
  describe 'when editing the customer ledger entries' do
    it 'has a shortcut for writing ledger entries' do
      expect do
        customer.add_to_ledger(200.0, :cash)
      end.to change{ Billingly::LedgerEntry.count }.by(1)
      Billingly::LedgerEntry.last.tap do |last|
        last.account.should == 'cash'
        last.amount.should == 200.0
      end
    end

    it 'can write ledger entries for several accounts at once' do
      invoice = create(:first_year, customer: customer).invoices.last
      expect do
        customer.add_to_ledger(200.0, :cash, :income, invoice: invoice)
      end.to change{ Billingly::LedgerEntry.count }.by(2)
      invoice.reload
      invoice.ledger_entries.count.should == 2
    end

    it 'has a reader for the whole ledger' do
      customer.add_to_ledger(100.0, :cash)
      customer.add_to_ledger(100.0, :cash, :income)
      customer.ledger[:cash].should == 200.0
      customer.ledger[:income].should == 100.0
    end
  end
  
  describe 'when subscribing to a plan' do
    let(:subscription){ customer.subscribe_to_plan(plan) }

    subject { subscription }
    
    [:payable_upfront, :description, :periodicity, :amount].each do |k|
      its(k){ should == plan.send(k) }
    end
    
    it 'Makes subscription immediate' do
      subscription.subscribed_on.to_time.to_s.should == Time.now.utc.to_s
    end
    
    it 'invoices payable_upfront plans right away' do
      expect do
        customer.subscribe_to_plan(create(:pro_50_yearly))    
      end.to change{ customer.invoices.count }.by(1)
    end

    it 'does not invoice non payable_upfront plans until later' do
      expect do
        customer.subscribe_to_plan(create(:pro_50_monthly))    
      end.not_to change{ customer.invoices.count }
    end
  end
  
  pending 'can not suscribe more than one time to the same plan'
  pending 'can\'t change to a smaller plan'
  pending 'generates invoice before changing a plan' 
  pending 'cannot change plan if debtor'

  it 'when changing plan' do
      pending
      Timecop.travel 45.days.ago
      old = customer.subscribe_to_plan(plan)
      Timecop.return 
      new = customer.subscribe_to_plan(build(:pro_50_yearly))
      old.reload
      old.unsubscribed_on.to_i.should == new.subscribed_on.to_i
  end 
  
  it 'Settles oldest invoice when receiving a payment' do
    subscription = customer.subscribe_to_plan(create(:pro_50_monthly))
    Timecop.travel 2.month.from_now
    oldest = subscription.generate_next_invoice
    newest = subscription.generate_next_invoice
    customer.credit_payment(200)
    oldest.reload
    newest.reload
    oldest.should be_paid
    newest.should_not be_paid
    Timecop.return
  end
  
  it 'Does not settle deleted invoices' do
    pending ''
  end
  
  it 'deactivates customers who missed a due-date' do
    subscription = create(:first_year, :overdue)

    Billingly::Customer.deactivate_debtors

    subscription.reload
    customer = subscription.customer
    customer.deactivated_debtor_since.utc.to_s.should == Time.now.utc.to_s
    customer.should be_debtor
  end
  
  it 'does not re-deactivate already deactivated customers' do
    subscription = create(:first_year, :overdue, :deactivated)

    expect do
      Billingly::Customer.deactivate_debtors
      subscription.reload
    end.not_to change{ subscription.customer.deactivated_debtor_since }

    Timecop.return
  end
  
  it 'does not deactivate customers because of deleted invoices' do
    customer = create(:first_year).customer
    customer.invoices.first.update_attribute(:deleted_on, Time.now)

    Timecop.travel 2.months.from_now
    Billingly::Customer.deactivate_debtors
    customer.reload
    customer.should_not be_debtor
  end
  
  describe 'when a debtor of a yearly subscription pays' do
    it 'tries to reactivate if previously deactivated' do
      customer = create(:first_year, :overdue, :deactivated).customer
      customer.should_receive(:reactivate_debtor)
      customer.credit_payment(200)
    end

    it 'does not try to reactivate if already active' do
      customer = create(:first_year, :overdue).customer
      customer.should_not_receive(:reactivate_debtor)
      customer.credit_payment(200)
    end

    it 'does not try to reactivate if amount paid does not settle current debt' do
      customer = create(:first_year, :overdue, :deactivated).customer
      customer.should_not_receive(:reactivate_debtor)
      customer.credit_payment(10)
    end
  end
  
  describe 'when reactivating a debtor of a yearly subscription' do
    before(:each) do
      @old = create(:first_year, :overdue, :deactivated)
      @old.customer.reactivate_debtor
      @new = @old.customer.active_subscription
    end
    
    it 'creates a new subscription' do
      @old.should_not == @new
    end
    
    it 'forfeits the old invoice' do
      invoice = @old.invoices.last
      invoice.deleted_on.should_not be_nil
      invoice.receipt.should be_nil
    end
    
    it 'creates a new invoice without the grace period used up on the previous one' do
      invoice = @new.invoices.first
      invoice.receipt.should_not be_nil
      inovice.
    end
    
    pending 'forfeits the old invoice'
    pending 're-enables the customer'
  end
  
  describe 'when debtor of a full-month subscription returns' do
    pending 'ends the old subscription and starts a new one, new subscription should not include the grace period'
    pending 'charges the old subscription'
    pending 're-enables the customer'
  end
  
end
