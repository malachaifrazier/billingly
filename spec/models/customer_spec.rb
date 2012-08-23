require 'spec_helper'

describe Billingly::Customer do
  let(:plan){ build(:pro_50_monthly) }
  let(:plan){ build(:pro_50_monthly) }
  let(:customer){ create(:customer) }
  describe 'when subscribing to a plan' do
    let(:subscription){ customer.subscribe_to_plan(plan) }

    subject { subscription }
    
    [:payable_upfront, :description, :length, :amount].each do |k|
      its(k){ should == plan.send(k) }
    end
    
    it('Makes subscription immediate') do
      subscription.subscribed_on.to_date.should == Date.today 
    end
  end
  
  describe 'when incurring on a one-time charge' do
    let(:a_date){ 3.days.from_now }
    subject do
      customer.schedule_one_time_charge(a_date, 10.0, 'setup fee')
    end
    
    its(:amount){ should == 10.0 }
    its(:charge_on){ should == a_date }
    its(:description){ should == 'setup fee' }
    
    it 'should not allow creating charges in the past' do
      customer.schedule_one_time_charge(5.days.ago, 1, 'invalid')
        .should be_nil
    end
  end

  pending 'can not suscribe more than one time to the same plan'
  pending 'can\'t change to a smaller plan'
  pending 'ending a subscription that is charged at the period\'s end should trigger the invoicing for usage incurred on so far. Whether you are changing to another plan or just leaving the site.'
  pending 'generates invoiceing before changeing a plan' 
  it 'when changing plan' do
      Timecop.travel 45.days.ago
      old = customer.subscribe_to_plan(plan)
      Timecop.return 
      new = customer.subscribe_to_plan(build(:pro_50_yearly))
      old.reload
      old.unsubscribed_on.to_i.should == new.subscribed_on.to_i
  end 

  describe 'when creating initial invoice' do
    subject do
      Timecop.travel 1.month.ago
      customer.subscribe_to_plan(plan)
      Timecop.return 
      customer.generate_invoice
    end
    
    its(:receipt){ should be_nil }
    its(:amount){ should == plan.amount }
    its(:due_on){ should == Invoice.default_grace_period + subject.created_at }
    its(:period_start){ should == customer.customer_since }
    its(:period_end){ should == subject.period_start + 1.month }
    
  end

  describe 'when invoicing' do
    
    pending 'does not create more than one invoice per period'

    pending 'invoices are calculated from the time of last invoice'
    pending 'sends an invoice for a monthly charge'
    pending 'sends an invoice for the yearly subscription'
    pending 'does not send invoices when in the middle of a yearly subscription'
    pending 'sends an invoice for a one time charge'
    pending 'sends an invoice for a monthly charge and a one time charge'
  end
  
  describe 'when receiving payment' do
    pending 'receives a payment from paypal'
    pending 'receives a payment with credit card'
    pending 'receiving payment tries to settle invoices immediately'
  end
  
  describe 'when settling accounts and sending receipts' do
    pending 'settles an invoice with the current balance'
    pending 'does not settle invoice if balance is not enough'
    pending 'the oldest invoice is the first to be charged'
  end
end
