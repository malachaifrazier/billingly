require 'spec_helper'

describe Billingly::RedemptionsController do
  render_views

  describe 'when showing the redemption form' do
    it 'shows the pre_signup form' do
      get :new
      response.body.should have_selector "input#promo_code"
    end
    
    it 'pre populates the promo code field with a get param' do
      get :new, promo_code: 'ABCD1'
      response.body.should have_selector 'input[name="promo_code"][value="ABCD1"]'
    end
  end
  
  describe 'when redeeming a promo code' do
    it 'subscribes and redirects to the subscriptions page' do
      post :create, promo_code: create(:promo_code).code
      response.should redirect_to subscriptions_path
      flash[:notice].should == 'Your promo code has been redeemed!'
    end
    
    it 'shows message when code was already used' do
      post :create, promo_code: create(:promo_code, redeemed_on: Time.now).code
      response.should redirect_to new_redemption_path
      flash[:invalid_promo_code].should == 'The promo code you entered was invalid'
    end
    
    it 'shows message when code was invalid' do
      post :create, promo_code: 'boguscode'
      response.should redirect_to new_redemption_path
      flash[:invalid_promo_code].should == 'The promo code you entered was invalid'
    end
    
    it 'shows message when current customer cannot subscribe to the given plan' do
      Billingly::Customer.any_instance.stub(can_subscribe_to?: false)
      post :create, promo_code: create(:promo_code).code
      response.should redirect_to new_redemption_path
      flash[:invalid_promo_code_plan]
        .should == "You can't subscribe to the plan provided by your promo code"
    end
    
    it 'has a callback when a non-customer tries to redeem a code, stores code in session' do
      controller.stub(current_customer: nil)
      promo_code = create(:promo_code)
      post :create, promo_code: promo_code.code
      response.should redirect_to subscriptions_path
      session[:current_promo_code].should == promo_code.code
      controller.current_promo_code.should == promo_code
      controller.current_promo_code_plan.should == promo_code.plan
    end
  end
end
