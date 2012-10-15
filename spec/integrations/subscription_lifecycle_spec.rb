require 'spec_helper'

# These tests try to mimic what goes on with the live system, with customers joining,
# time passing by and the periodic tasks executing periodically as they should.

describe 'SubscriptionLifecycle' do
  describe 'when customer pays yearly in advance' do
    let(:customer){ create(:customer) }

    it 'Customer joins and pays on time for the first 2 years' do
      # This example tests the lifecycle of the first two years of
      # a subscription in which the customer pays upfront on a per-year basis.
      # The customer pays a few days after subscribing and then again the next year.

      customer.subscribe_to_plan(build(:pro_50_yearly))
      days_go_by 3
      customer.credit_payment(100.0)
      assert_ledger customer, cash: 0.01, paid: 100.0, spent: 99.99

      days_go_by 365
      customer.credit_payment(100.0)
      
      assert_ledger customer, cash: 0.02, paid: 200.0, spent: 199.98
      customer.should_not be_deactivated
      customer.should_not be_debtor
    end
    
    it 'Customer pays her first invoice and then misses a payment' do
      # This example shows what happens when a paying customer misses a payment,
      # and what happens when the customer decides to re-join the service.

      customer.subscribe_to_plan(build(:pro_50_monthly))

      days_go_by 30
      customer.reload
      customer.should_not be_deactivated
      customer.should_not be_debtor
      customer.credit_payment(10.0)
      assert_ledger customer, cash: 0.1, paid: 10.0, spent: 9.9

      days_go_by 50
      customer.reload
      customer.should be_deactivated
      customer.should be_debtor
    end
    
    it 'Customer changes to another plan' do
      date = Date.today.beginning_of_year
      Timecop.travel date
      customer.subscribe_to_plan(build(:pro_50_monthly))
      customer.credit_payment(10.0)
      days_go_by 25

      customer.subscribe_to_plan(build(:pro_50_yearly))
      
      # The last invoice for the last plan should have been prorated
      assert_ledger customer, cash: 2.34, paid: 10.0, spent: 7.66

      days_go_by 5
      customer.credit_payment(100.0)
      assert_ledger customer, cash: 2.35, paid: 110.0, spent: 107.65
    end
    
    it 'Customer leaves the site before paying their last invoice, which was not due yet' do
      # This example shows that if an invoice becomes overdue after the customer
      # voluntarily cancelled his subscrption, they still need to pay in order to
      # reactivate their account.
      customer = create(:first_year).customer
      days_go_by 1
      customer.deactivate_left_voluntarily
      customer.should_not be_debtor
      days_go_by 30
      customer.reload
      customer.should be_debtor
      customer.reactivate.should be_nil
      days_go_by 1
      customer.reload
      customer.credit_payment(200)
      customer.reactivate.should_not be_nil
    end
    
    it 'Customer subscribed but never paid not even his first invoice' do
      # This example shows that customers who subscribe to a plan and
      # don't even pay their first invoice are deactivated too.
      customer = create(:first_year).customer
      days_go_by 20
      customer.reload
      customer.should be_debtor
      customer.should be_deactivated
    end

    it 'Customer missed a payment but then returned to the site and paid' do
      # This example shows how a customer who missed a payment can pay
      # and get his account reactivated.
      customer = create(:first_year).customer
      days_go_by 20
      customer.credit_payment(200)
      customer.reload
      customer.reactivate.should_not be_nil
    end
    
    it 'Customer who was disabled pays her debt but rectivates to a different plan' do
      # This example shows how a customer can deactivate her account then come back
      # and reactivate to a different plan
      customer = create(:first_year).customer
      days_go_by 20
      customer.credit_payment(200)
      customer.reload
      customer.reactivate(build(:pro_100_monthly)).should_not be_nil
    end
  
    it 'Customer signs up for a trial and upgrades before trial ends' do
      # This example shows a customer who starts on a trial and then upgrades before
      # trial ends. Her account never reaches the deactivated state.
      customer = create(:trial).customer
      days_go_by 10
      customer.subscribe_to_plan(build(:pro_100_monthly))
      customer.should_not be_doing_trial
    end
    
    it 'Customer signs up for a trial and upgrades after trial ends' do
      # This example shows a customer who had a trial period that expired,
      # then re-joined the site.
      customer = create(:trial).customer
      days_go_by 20
      customer.reload
      customer.should be_deactivated
      days_go_by 10
      customer.reactivate(build(:pro_100_monthly))
      customer.should_not be_doing_trial
      customer.should_not be_deactivated
    end
  end
end
