require 'spec_helper'

describe Billingly::Payment do
  it 'should credit payments towards a customer balance' do
    amount = 150.0
    customer = create(:customer)
    should_add_to_ledger(customer, 2) do
      payment = Billingly::Payment.credit_for(customer, amount)
      payment.amount.should == payment.amount
      should_have_ledger_entries(customer, amount, :cash, :paid, payment: payment)
    end
  end
end
