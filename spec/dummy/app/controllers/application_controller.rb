class ApplicationController < ActionController::Base
  protect_from_forgery
  
  def current_customer 
    customer = Billingly::Customer.find(session[:customer_id])
    return customer if customer

    Billingly::Customer.create!(email: 'you@example.com').tap do |customer|
      session[:customer_id] = customer.id
    end
  end
end
