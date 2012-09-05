require 'spec_helper'

describe Billingly::SubscriptionsController do
  let(:customer){ create :customer }

  before(:each) do
    controller.stub current_customer: customer
  end

  it 'lists all availble plans' do
    get :show
  end

  it 'subscribes a customer to a plan' do
    plan = create :pro_50_monthly
    customer.should_receive(:subscribe_to_plan).with(plan)
    post :create, plan_id: plan.id
  end

  it 'does not subscribe a customer to a bogus plan' do
    customer.should_not_receive(:subscribe_to_plan)
    expect do
      post :create, plan_id: 'blah'
    end.to raise_exception ActiveRecord::RecordNotFound
    response.should be_not_found
  end
end

