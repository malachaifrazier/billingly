require 'spec_helper'

describe Billingly::Customer do
  let(:plan){ build(:pro_50_monthly) }
  
  describe 'when subscribing to a plan' do
    let(:subscription){ create(:customer).subscribe_to_plan(plan) }

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
      create(:customer).schedule_one_time_charge(a_date, 10.0, 'setup fee')
    end
    
    its(:amount){ should == 10.0 }
    its(:charge_on){ should == a_date }
    its(:description){ should == 'setup fee' }
    
    it 'should not allow creating charges in the past' do
      create(:customer).schedule_one_time_charge(5.days.ago, 1, 'invalid')
        .should be_nil
    end
  end
  
  pending 'when changing plan'
  
  describe 'when invoicing' do
    pending 'first invoice is calculated from the date the user first became a customer'
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
