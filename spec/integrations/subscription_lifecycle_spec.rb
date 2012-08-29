require 'spec_helper'

describe 'SubscriptionLifecycle' do
  describe 'when customer pays yearly in advance' do
    let(:customer){ create(:customer) }

    it 'All goes as expected for the first two years' do
      # This example tests the lifecycle of the first two years of
      # a subscription in which the customer pays upfront on a per-year basis.
      # All payments are done successfully before the invoices are due.
      
      # Customer sings up to one of our existing plans.
      customer.subscribe_to_plan(build(:pro_50_yearly))
      assert_ledger customer, ioweyou: 99.99, services_to_provide: 99.99

      # 2 days later, the customer performs the payment
      Timecop.travel 2.days.from_now
      customer.credit_payment(100.0)
      assert_ledger customer, cash: 0.01, income: 100.0, paid_upfront: 99.99

      # About one year later, the actual loss should be processed, and
      # debited from the paid_upfront balance.
      # The next invoice should be created for the customer
      Timecop.travel 1.year.from_now
      Billingly::Invoice.acknowledge_expenses
      assert_ledger customer, cash: 0.01, income: 100.0, expenses: 99.99

      Billingly::Subscription.generate_next_invoices
      assert_ledger customer, cash: 0.01, income: 100.0, expenses: 99.99,
        ioweyou: 99.99, services_to_provide: 99.99

      Timecop.travel 1.days.from_now
      customer.credit_payment(100.0)
      assert_ledger customer, cash: 0.02, income: 200.0, expenses: 99.99, paid_upfront: 99.99

      Timecop.return
    end
    
    it 'Missed a payment after a year' do
      # This example shows what happens when a paying customer misses a payment,
      # and what happens when the customer decides to re-join the service.

      customer.subscribe_to_plan(build(:pro_100_yearly))
      
      Timecop.travel 2.days.from_now
      customer.credit_payment(200.0)

      Timecop.travel 1.year.from_now
      Billingly::Invoice.acknowledge_expenses
      Billingly::Subscription.generate_next_invoices

      assert_ledger customer, cash: 0.01, expenses: 199.99, income: 200.0,
        ioweyou: 199.99, services_to_provide: 199.99
      
      Timecop.travel 20.days.from_now
      Billingly::Subscription.process_debtors
      customer.reload
      customer.should be_debtor
      
      # When the user misses an upfront payment:
      #   Their old subscription should be terminated on the day they become a debtor.
      #   Their ledger should be balanced to cancel out the ioweyou and the services_to_provide.
      #
      # When they re-access the site:
      #   They should be required to pay in order to re-enable their account.
      #   A new subscription should be created for them, the first period's length should not
      #   include the days during which the user was able to access the site before it was
      #   deactivated.
      #   
      #   
    end
    
    it 'Got updated to a better plan mid-year' do
    end
    
    it 'Got canceled before the first year was over' do
    end
    
    it 'Was never paid after subscribed' do
    end

    it 'missed a payment but then returned to the site and paid' do
    end
  end
  
  describe 'when customer pays after every month of usage' do
    it 'All goes as expected for the first 3 months' do
      # This example tests the lifecycle of the first two years of
      # a subscription in which the customer pays upfront on a per-year basis.
      # All payments are done successfully before the invoices are due.
    end
    
    it 'When the user misses a monthly payment' do
      # When the user misses a due-month payment:
      #   Their old subscription should be terminated on the day they become a debtor.
      #   Their ledger should be kept as-is, with the debt and the expense in place.
      #
      # When they re-access the site:
      #   They should be required to pay their debt before they can continue. 
      #   (When their balance is enough to pay for their debt they should be re-enabled,
      #     a new subscription should be created starting on the day the payment was received)
      #   
    end
    
    it 'Got updated to a better plan mid-year' do
    end
    
    it 'Got canceled before the first year was over' do
    end
    
    it 'Was never paid after subscribed' do
    end

    it 'missed a payment but then returned to the site and paid' do
    end
  end
  
  pending 'when changing from a paid-upfront plan to a due-month plan'
  pending 'when changing from a due-month plan to a paid-upfront plan'
end
