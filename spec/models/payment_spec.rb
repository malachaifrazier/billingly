require 'spec_helper'

describe Billingly::Payment do
  it 'should credit payments towards a customer balance' do
    amount = 150.0
    customer = create(:customer)
    expect do
      payment = Billingly::Payment.credit_for(customer, amount)
      payment.amount.should == payment.amount
      %w(cash income).each do |account|
        payment.ledger_entries.find_by_account(account).tap do |l|
          l.amount.should == amount
          l.receipt.should be_nil
          l.invoice.should be_nil
          l.payment.should == payment
          l.customer == customer 
        end
      end
    end.to change{ customer.ledger_entries.count }.by(2)
  end
end
