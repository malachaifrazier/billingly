require 'spec_helper'

describe ApplicationController do
  let(:customer){ create :customer }

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
  
  describe 'when denying access to deactivated customers' do
    it 'does not blow up when no customer' do
      controller.stub current_customer: nil
      controller.should_receive(:redirect_to).and_raise('Redirected')
      expect do
        controller.requires_active_customer
      end.to raise_exception('Redirected')
    end

    it 'redirects deactivated customers to reactivate their account' do
      controller.stub current_customer: create(:deactivated_customer)
      controller.should_receive(:redirect_to).with(controller: 'billingly/subscriptions', action: 'index')
      controller.requires_active_customer
    end
    
    it 'grants passage to active customers' do
      controller.stub current_customer: create(:customer)
      controller.should_not_receive(:redirect_to)
      controller.requires_active_customer.should be_nil
    end
  end
end

