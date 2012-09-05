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
      customer.subscribe_to_plan(build(:pro_50_monthly))
      customer.credit_payment(10.0)
      days_go_by 25

      customer.subscribe_to_plan(build(:pro_50_yearly))
      
      # The last invoice for the last plan should have been prorated
      assert_ledger customer, cash: 2.08, paid: 10.0, spent: 7.92

      days_go_by 5
      customer.credit_payment(100.0)
      assert_ledger customer, cash: 2.09, paid: 110.0, spent: 107.91
    end
    
    it 'Customer leaves the site before paying their last invoice, which was not due yet' do
      pending
    end
    
    it 'Customer subscribed but never paid not even his first invoice' do
      pending
    end

    it 'Customer missed a payment but then returned to the site and paid' do
      pending
    end
    
    it 'Customer who was disabled pays her debt but re-joins to a different' do
      pending
    end
  end
end
