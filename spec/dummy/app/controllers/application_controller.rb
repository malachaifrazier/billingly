class ApplicationController < ActionController::Base
  protect_from_forgery

  def current_customer
    customer = Billingly::Customer.find_by_id(session[:customer_id])
    return customer if customer

    fresh_customer
  end

  # This is a host app helper method for creating a new customer and
  # using it on the session as the current customer
  def fresh_customer
    Billingly::Customer.create!.tap do |customer|
      session[:customer_id] = customer.id
    end
  end
end
