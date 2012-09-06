require 'spec_helper'

describe Billingly::SubscriptionsController do
  let(:customer){ create :customer }

  pending 'test that all actions require a customer'

  it 'requires a customer to be logged in for all actions' do
    controller.stub current_customer: nil
    controller.should_receive :requires_customer
    get :new
  end
  
  describe 'when requiring a customer' do
    it 'exits when there is none' do
      controller.stub current_customer: nil
      controller.should_receive :on_empty_customer
      controller.requires_customer
    end

    it 'continues when there is one' do
      controller.stub current_customer: customer
      controller.should_not_receive :on_empty_customer
      controller.requires_customer
    end
  end

  it 'redirects to show' do
    controller.should_receive(:redirect_to).with :show
    controller.on_subscription_success create(:first_month)
  end

  describe 'when customer logged in' do
    before(:each) do
      controller.stub current_customer: customer
    end

    it 'lists all availble plans' do
      get :new
      assigns(:plans).should == Billingly::Plan.all
    end

    it 'subscribes a customer to a plan' do
      plan = create :pro_50_monthly
      customer.should_receive(:subscribe_to_plan).with(plan)
      controller.should_receive :on_subscription_success
      post :create, plan_id: plan.id
    end

    it 'does not subscribe a customer to a bogus plan' do
      customer.should_not_receive(:subscribe_to_plan)
      controller.should_not_receive :on_subscription_success
      expect do
        post :create, plan_id: 'blah'
      end.to raise_exception ActiveRecord::RecordNotFound
    end
  end
end

