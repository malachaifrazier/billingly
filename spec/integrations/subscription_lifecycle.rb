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
      customer.ledger[:ioweyou].to_f.should == 99.99
      customer.ledger[:services_to_provide].to_f.should == 99.99

      # 2 days later, the customer performs the payment
      Timecop.travel 2.days.from_now
      customer.credit_payment(100.0)
      customer.reload
      customer.ledger[:ioweyou].should == 0.0
      customer.ledger[:services_to_provide].should == 0.0
      customer.ledger[:cash].should == 0.01
      customer.ledger[:income].to_f.should == 100.0
      customer.ledger[:paid_upfront].to_f.should == 99.99

      # About one year later, the actual loss should be processed, and
      # debited from the paid_upfront balance.
      # The next invoice should be created for the customer
      Timecop.travel 1.year.from_now
      Billingly::Invoice.acknowledge_expenses
      customer.reload
      customer.ledger[:ioweyou].should == 0.0
      customer.ledger[:services_to_provide].should == 0.0
      customer.ledger[:cash].should == 0.01
      customer.ledger[:income].to_f.should == 100.0
      customer.ledger[:paid_upfront].to_f.should == 0.0
      customer.ledger[:expenses].to_f.should == 99.99

      Billingly::Subscription.generate_next_invoices
      customer.reload
      customer.ledger[:ioweyou].should == 99.99
      customer.ledger[:services_to_provide].should == 99.99
      customer.ledger[:cash].should == 0.01
      customer.ledger[:income].to_f.should == 100.0
      customer.ledger[:paid_upfront].to_f.should == 0.0
      customer.ledger[:expenses].to_f.should == 99.99

      Timecop.travel 1.days.from_now
      customer.credit_payment(100.0)
      customer.reload
{:ioweyou=>0.0, :services_to_provide=>0.0, :cash=>0.02, :income=>200.0, :paid_upfront=>99.99, :expenses=>99.99}
      customer.ledger[:ioweyou].should == 0.0
      customer.ledger[:services_to_provide].should == 0.0
      customer.ledger[:cash].should == 0.02
      customer.ledger[:income].to_f.should == 200.0
      customer.ledger[:paid_upfront].to_f.should == 99.99
      customer.ledger[:expenses].to_f.should == 99.99
      Timecop.return
    end
    
    it 'Was not renewed after the first year' do
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
    
    it 'Was not renewed after the first year' do
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
end
