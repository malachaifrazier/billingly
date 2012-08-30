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
    
    it 'defaults all accounts on ledger to 0.0' do
      customer.ledger[:cash].should == 0.0
    end
  end
  
  describe 'when first subscribing to a plan' do
    let(:subscription){ customer.subscribe_to_plan(plan) }

    subject { subscription }
    
    [:payable_upfront, :description, :periodicity, :amount].each do |k|
      its(k){ should == plan.send(k) }
    end
    
    it 'Makes subscription immediate' do
      subscription.subscribed_on.to_time.to_s.should == Time.now.utc.to_s
    end
    
    it 'creates first invoice right away' do
      expect do
        customer.subscribe_to_plan(create(:pro_50_yearly))    
      end.to change{ customer.invoices.count }.by(1)
    end
  end
  
  describe 'when changing from one plan to another' do
    it 'new subscription starts where the old one terminated' do
      old = create(:first_month)
      new = old.customer.subscribe_to_plan(build(:pro_50_yearly))
      old.reload
      old.should_not == new 
      old.unsubscribed_on.to_s.should == new.subscribed_on.to_s
    end

    it 'terminates the old subscription' do
      subscription = create(:first_month)
      Billingly::Subscription.any_instance.should_receive(:terminate)
      subscription.customer.subscribe_to_plan(build(:pro_50_yearly))
    end
  end
  
  describe 'when crediting a payment on the users account' do
    it 'Credits it on the customer balance' do
      customer = create(:first_month).customer
      Billingly::Payment.should_receive(:credit_for).with(customer, 200.0)
      customer.credit_payment(200.0)
    end

    it 'Settles oldest invoice when receiving a payment' do
      customer = create(:first_month).customer
      Billingly::Invoice.should_receive(:charge_all).with(customer.invoices)
      customer.credit_payment(200.0)
    end
    
    it 'Tries to reactivate the user if she was a debtor' do
      customer = create(:first_month).customer
      customer.should_receive(:reactivate)
      customer.credit_payment(200.0)
    end
  end
  
  describe 'when identifying debtors' do
    it 'has a method for fetching all the debtors' do
      3.times{ create(:first_year, :overdue, :deactivated) }
      Billingly::Customer.debtors.count.should == 3
    end

    it 'unpaid deleted invoices do not make you a debtor' do
      3.times{ create(:first_year, :overdue, :deactivated) }
      customer = create(:first_year).customer
      customer.invoices.first.update_attribute(:deleted_on, Time.now)
      Timecop.travel 2.months.from_now

      Billingly::Customer.debtors.count.should == 3
      Timecop.return
    end
  end

  describe 'when deactivating an account' do
    it 'terminates last subscription' do
      Billingly::Subscription.any_instance.should_receive(:terminate)
      create(:first_year).customer.deactivate
    end
    
    it 'sets the deactivated flag' do
      customer = create(:first_year).customer
      customer.deactivate.should_not be_nil
      customer.should be_deactivated
    end

    it 'sets the deactivated flag' do
      create(:first_year, :deactivated).customer.deactivate.should be_nil
    end
  end
  
  describe 'deactivating a debtors' do
    it 'mass deactivates customers who missed a due-date' do
      subscription = create(:first_year, :overdue)

      expect do
        expect do
          Billingly::Customer.deactivate_all_debtors
          subscription.reload
        end.to change{ subscription.terminated? }
      end.to change{ subscription.customer.deactivated? }

      subscription.customer.deactivated_since.utc.to_s.should == Time.now.utc.to_s
    end
  
    it 'does not mass re-deactivate already deactivated debtors' do
      subscription = create(:first_year, :overdue, :deactivated)
      expect do
        expect do
          Billingly::Customer.deactivate_all_debtors
          subscription.reload
        end.not_to change{ subscription.terminated? }
      end.not_to change{ subscription.customer.deactivated? }
    end
  end
  
  describe 'when reactivating an account' do
    describe 'when successfull' do
      before :each do
        @customer = create(:first_year, :overdue, :deactivated).customer
        Billingly::Payment.credit_for(@customer, 200)
        Billingly::Invoice.charge_all(@customer.invoices)
      end

      it 'reactivates immediately' do
        @customer.should be_deactivated
        @customer.reactivate.should_not be_nil
        @customer.should_not be_deactivated
      end
    
      it 'creates a new subscription to the same plan automatically' do
        old = @customer.subscriptions.last
        @customer.reactivate.should_not be_nil
        @customer.reload
        @customer.active_subscription.should_not == old
      end

      it 'lets you signup to another plan when reactivating' do
        old = @customer.subscriptions.last
        expect do
          @customer.reactivate(create(:pro_50_monthly)).should_not be_nil
        end.to change{ @customer.active_subscription.description }
      end

      it 'uses the same old plan if not providing a new plan to reactivate to' do
        expect do
          @customer.reactivate.should_not be_nil
        end.not_to change{ @customer.active_subscription.description }
      end
    end
      
    it 'does not try to reactivate if already active' do
      customer = create(:first_year, :overdue).customer
      customer.reactivate.should be_nil
    end

    it 'does not try to reactivate if customer owes invoices' do
      customer = create(:first_year, :overdue, :deactivated).customer
      customer.should be_deactivated
      customer.reactivate.should be_nil
      customer.should be_deactivated
    end
  end
end
