require 'spec_helper'

describe Billingly::Customer do
  let(:plan){ build(:pro_50_monthly) }
  let(:customer){ create(:customer) }
  
  it 'has a ledger' do
    Billingly::Payment.credit_for(customer, 100.0)
    Billingly::Payment.credit_for(customer, 200.0)
    customer.ledger[:cash].should == 300
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

  it 'when changing plan' do
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
end
