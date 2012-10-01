require 'spec_helper'

describe UseCasesController do
  before { create(:pro_50_monthly, payable_upfront: true) }
  let(:customer){ controller.current_customer }
  
  it 'credits 5 dollars into the customer account' do
    customer
    post :credit_payment
    customer.ledger[:cash].to_f.should == 5.0
  end

  it 'flashes a notice after crediting the payment' do
    post :credit_payment
    flash.notice.should == "$5 were credited to your account"
  end
    
  it 'creates an unsubscribed customer' do
    post :create_new
    customer.active_subscription.should be_nil
    customer.should_not be_deactivated
  end

  it 'creates a customer who is doing a trial period' do
    post :create_trial
    customer.should be_doing_trial
  end

  it 'creates a customer with an expired trial period' do
    post :create_expired_trial
    customer.should be_deactivated
    customer.deactivation_reason.should == 'trial_expired'
  end

  it 'creates a customer who has been using the site for a while' do
    post :create_old_user
    customer.should_not be_deactivated
    customer.invoices.size.should == 3
    customer.invoices.first.should be_paid
    customer.invoices.last.should_not be_paid
  end
  
  it 'creates a customer whose account has been deactivated for lack of payment' do
    post :create_deactivated_debtor
    customer.should be_deactivated
    customer.should be_debtor
    customer.invoices.size.should == 2
    customer.invoices.first.should be_paid
    customer.invoices.last.should_not be_paid
  end

  [:credit_payment, :create_new, :create_trial, :create_expired_trial,
   :create_old_user, :create_deactivated_debtor].each do |action|
    it "redirects to subscriptions_path after #{action}" do
      post action
      response.should redirect_to subscriptions_path
    end
  end
  
  [:credit_payment, :create_new, :create_trial, :create_expired_trial,
   :create_old_user, :create_deactivated_debtor].each do |action|
    it "Sets notice after calling #{action}" do
      post action
      flash[:notice].should_not be_nil
    end
  end

  [:create_new, :create_trial, :create_expired_trial,
   :create_old_user, :create_deactivated_debtor].each do |action|
    it "Changes the customer after calling #{action}" do
      old_customer = controller.current_customer
      post action
      controller.current_customer.should_not == old_customer
    end
  end
end
