require 'spec_helper'

describe Billingly::Customer do
  let(:plan){ build(:pro_50_monthly) }
  let(:customer){ create(:customer) }
  
  describe 'when editing the customer ledger entries' do
    it 'validates email' do
      customer.should be_valid
      build(:customer, email: 'blabalabl').should_not be_valid
    end

    it 'has a shortcut for writing ledger entries' do
      expect do
        customer.add_to_journal(200.0, :cash)
      end.to change{ Billingly::JournalEntry.count }.by(1)

      Billingly::JournalEntry.last.tap do |last|
        last.account.should == 'cash'
        last.amount.should == 200.0
      end
    end

    it 'can write ledger entries for several accounts at once' do
      invoice = create(:first_year, customer: customer).invoices.last
      expect do
        customer.add_to_journal(200.0, :cash, :paid, invoice: invoice)
      end.to change{ Billingly::JournalEntry.count }.by(2)
      invoice.reload
      invoice.journal_entries.count.should == 2
    end

    it 'has a reader for the whole ledger' do
      customer.add_to_journal(100.0, :cash)
      customer.add_to_journal(100.0, :cash, :paid)
      customer.ledger[:cash].should == 200.0
      customer.ledger[:paid].should == 100.0
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

  it 'can subscribe directly to a trial' do
    subscription = customer.subscribe_to_plan(plan, 10.days.from_now)
    customer.should be_doing_trial
    subscription.should be_trial
  end

  it 'saves a reference to the plan when subscribing to a plan' do
    subscription = customer.subscribe_to_plan(plan)
    subscription.plan.should == plan
  end
    
  it 'does not save a reference to the plan when subscribing to a non-plan' do
    pending
  end
  
  it 'keeps the plan when resubscribing to another subscription' do
    pending
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
      Billingly::Subscription.any_instance.should_receive(:terminate_changed_subscription)
      subscription.customer.subscribe_to_plan(build(:pro_50_yearly))
    end
    
    it 'can move from a trial period to an actual plan' do
      old = create(:trial)
      Timecop.travel 10.days.from_now
      new = old.customer.subscribe_to_plan(build(:pro_50_yearly))
      old.should_not == new
      new.should_not be_trial
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
      customer.should_receive(:charge_pending_invoices)
      customer.credit_payment(200.0)
    end
    
    it 'Tries to reactivate the user when receiving payments' do
      customer = create(:first_month).customer
      customer.deactivate_debtor
      customer.should_receive(:reactivate)
      customer.credit_payment(200.0)
    end

    it 'Does not try to reactivate if the customer left in her own terms' do
      customer = create(:first_month).customer
      customer.deactivate_left_voluntarily
      customer.should_not_receive(:reactivate)
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
      create(:first_year).customer.deactivate_debtor
    end
    
    it 'sets the deactivated flag' do
      customer = create(:first_year).customer
      customer.deactivate_debtor.should_not be_nil
      customer.should be_deactivated
    end

    it 'does not deactivate if already deactivated' do
      create(:first_year, :deactivated).customer.deactivate_debtor.should be_nil
    end
    
    %w(debtor trial_expired left_voluntarily).each do |reason|
      it "has a shortcut for deactivating using #{reason}" do
        customer = create(:first_year).customer.send("deactivate_#{reason}")
        customer.should_not be_nil
        customer.deactivation_reason.should == reason
      end
      
      it "when deactivating because #{reason} the subscription is ended because #{reason} too" do
        customer = create(:first_year).customer.send("deactivate_#{reason}")
        customer.should_not be_nil
        customer.subscriptions.last.unsubscribed_because.should == reason
      end
    end
    
    it 'validates deactivated users have a deactivation reason' do
      customer = build(:customer, deactivated_since: Time.now)
      customer.should_not be_valid
      customer.errors.should have_key(:deactivation_reason)
    end
    
    it 'validates that users with a deactivation reason have a deactivation date' do
      customer = build(:customer, deactivation_reason: :debtor)
      customer.should_not be_valid
      customer.errors.should have_key(:deactivated_since)
    end

    it 'is valid if both deactivated date and reason are empty' do
      build(:customer).should be_valid
    end

    it 'validates the deactivation reason to be one of the preset ones' do
      build(:customer, deactivated_since: Time.now, deactivation_reason: :bogus)
        .should_not be_valid
    end
  end
  
  describe 'when fetching the active subscription' do
    it 'Should not have an active subscription when deactivated' do
      customer = create(:first_year).customer
      customer.deactivate_debtor
      customer.active_subscription.should be_nil
    end
    
    it 'Should have an active subscription while active' do
      create(:first_year).customer.active_subscription.should_not be_nil
    end
  end
  
  describe 'when customer is on trial' do
    it 'is on trial period' do
      create(:trial).customer.should be_doing_trial
    end
    
    it 'is not on trial period' do
      create(:first_month).customer.should_not be_doing_trial
    end
    
    it 'has a shortcut for checking days left on trial' do
      customer = create(:trial).customer
      customer.trial_days_left.should == 15
    end
    
    it 'does not have any trial, hence no days left' do
      customer = create(:first_month).customer
      customer.trial_days_left.should be_nil
    end
  end
  
  describe 'when reactivating an account' do
    describe 'when successfull' do
      before :each do
        @customer = create(:first_year, :overdue, :deactivated).customer
        Billingly::Payment.credit_for(@customer, 200)
        @customer.charge_pending_invoices
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
        end.to change{ @customer.subscriptions.last.description }
      end

      it 'uses the same old plan if not providing a new plan to reactivate to' do
        expect do
          @customer.reactivate.should_not be_nil
        end.not_to change{ @customer.subscriptions.last.description }
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
  
  describe 'when checking if the customer can upgrade to a certain plan' do
    [:pro_50_monthly, :pro_50_yearly, :pro_100_monthly, :pro_100_yearly].each do |plan|
      it "always lets customers on trial period subscribe, using #{plan}" do
        customer = create(:trial).customer
        customer.can_subscribe_to?(create(plan)).should be_true
      end
    end
    
    it 'lets the customer subscribe if not subscribed yet' do
      customer = create(:customer)
      plan = create(:pro_100_yearly)
      customer.can_subscribe_to?(plan).should be_true
    end

    it 'does not let customer subscribe to the same plan' do
      customer = create(:customer)
      plan = create(:pro_100_yearly)
      customer.subscribe_to_plan(plan)
      customer.can_subscribe_to?(plan).should be_false
    end
  end
  
  describe 'when charging pending invoices' do
    let(:customer){ create(:first_month).customer }
    it 'should charge all unpaid invoices' do
      Billingly::Customer.any_instance.stub(ledger: {cash: 300})

      expect do
        customer.charge_pending_invoices
      end.to change{ customer.invoices.where(paid_on: nil).count }.by(-1)
    end
    
    it 'should not settle invoice if customer does not have enough money in balance' do
      expect do
        customer.charge_pending_invoices
      end.not_to change{ customer.invoices.where(paid_on: nil).count }
    end
    
    it 'should settle oldest invoice first' do
      subscription = customer.active_subscription
      Timecop.travel 1.month.from_now
      oldest = subscription.invoices.first
      latest = subscription.generate_next_invoice

      # We credit the customer balance after creating the second invoice, because
      # 'generate_next_invoice' will charge it immediately otherwise.
      subscription.customer.add_to_journal(10, :cash)
  
      customer.charge_pending_invoices
      oldest.reload
      oldest.should be_paid

      latest.reload
      latest.should_not be_paid
    end
    
    it 'should not settle later invoices if the prior ones have been settled' do 
      subscription = customer.active_subscription
      Timecop.travel 1.month.from_now
      oldest = subscription.invoices.first
      oldest.update_attribute(:amount, 1000)
      latest = subscription.generate_next_invoice

      # We credit the customer balance after creating the second invoice, because
      # 'generate_next_invoice' will charge it immediately otherwise.
      subscription.customer.add_to_journal(10, :cash)
  
      customer.charge_pending_invoices
      oldest.reload
      oldest.should_not be_paid

      latest.reload
      latest.should_not be_paid
    end
  end
  
  it 'can set a do-not-email flag' do
    create(:customer).should_not be_do_not_email
  end
  
  describe 'when redeeming special plan codes' do
    let(:code){ Billingly::SpecialPlanCode.generate_for_plan(plan,1).first }

    it 'subscribes to the special plan setting the code as redeemed' do
      customer = create(:customer)
      expect do
        customer.redeem_special_plan_code(code.code)
      end.to change{ customer.active_subscription }
      code.reload
      code.should be_redeemed
      code.customer.should == customer
    end
    
    it 'does not subscribe if the code did not exist' do
      customer = create(:customer)
      customer.redeem_special_plan_code("blabalbbla").should be_nil
    end
    
    it 'does not subscribe if the code was already redeemed' do
      customer = create(:customer)
      customer.redeem_special_plan_code(code.code).should_not be_nil
      customer.redeem_special_plan_code(code.code).should be_nil
    end
  end
end
