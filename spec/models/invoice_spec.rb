require 'spec_helper'

describe Billingly::Invoice do
  let(:invoice) do
    create(:fourth_month).generate_next_invoice
  end
  
  let(:upfront_invoice) do
    create(:fourth_year).generate_next_invoice
  end

  it 'is deemed paid when there is a receipt associated to it' do
    invoice.should_not be_paid
    invoice.create_receipt(customer: invoice.customer, paid_on: Time.now)
    invoice.should be_paid
  end
  
  describe 'when settling an invoice' do
    it 'generates a receipt' do
      Billingly::Customer.any_instance.stub(ledger: {cash: 500})
      invoice.receipt.should be_nil
      invoice.settle.should_not be_nil
      invoice.reload
      invoice.receipt.should_not be_nil
    end

    it 'creates ledger entries for a subscription that was paid on due-month' do
      Billingly::Customer.any_instance.stub(ledger: {cash: 500})
      customer = invoice.customer
      
      should_add_to_ledger(customer, 2) do
        receipt = invoice.settle
        should_have_ledger_entries(customer, -(invoice.amount), :debt, :cash,
          receipt: receipt, subscription: invoice.subscription)
      end
    end

    it 'creates ledger entries for a subscription that was paid upfront' do
      Billingly::Customer.any_instance.stub(ledger: {cash: 500})
      customer = upfront_invoice.customer

      should_add_to_ledger(customer, 4) do
        receipt = upfront_invoice.settle
        extra = {receipt: receipt, subscription: upfront_invoice.subscription}
        should_have_ledger_entries(customer, -(upfront_invoice.amount),
          :cash, :services_to_provide, :ioweyou, extra)
        should_have_ledger_entries(customer, upfront_invoice.amount, :paid_upfront, extra)
      end
    end

    it 'does not settle if the customer balance is not enough to cover it' do
      Billingly::Customer.any_instance.stub(ledger: {cash: 0})
      invoice.settle.should be_nil
    end

    it 'does not try to settle if already settled' do
      Billingly::Customer.any_instance.stub(ledger: {cash: 200})
      invoice.settle.should_not be_nil
      invoice.settle.should be_nil
    end
  end
  
  describe 'when an invoices covered period ends' do
    it 'Acknowledges the expense of providing the service to the user, debiting from their upfront payment' do
      Billingly::Customer.any_instance.stub(ledger: {cash: 500})
      customer = upfront_invoice.customer
      amount = upfront_invoice.amount
      upfront_invoice.settle

      Timecop.travel(1.year.from_now + 1.day)

      should_add_to_ledger(customer, 2) do
        upfront_invoice.acknowledge_expense
        extra = {invoice: upfront_invoice, subscription: upfront_invoice.subscription}
        should_have_ledger_entries(customer, -(amount), :paid_upfront, extra)
        should_have_ledger_entries(customer, amount, :expenses, extra)
      end

      upfront_invoice.should be_acknowledged_expense

      Timecop.return
    end
    
    it 'does not acknowledge the expense if the invoice period is not over yet' do
      Billingly::Customer.any_instance.stub(ledger: {cash: 500})
      upfront_invoice.settle
      Timecop.travel 6.months.from_now
      expect do
        upfront_invoice.acknowledge_expense
      end.not_to change{ upfront_invoice.ledger_entries.count }
      upfront_invoice.should_not be_acknowledged_expense
      Timecop.return
    end
    
    it 'does not ackwowledge the expense if the invoice has not been paid yet' do
      Billingly::Customer.any_instance.stub(ledger: {cash: 500})
      Timecop.travel 370.days.from_now
      expect do
        upfront_invoice.acknowledge_expense
      end.not_to change{ upfront_invoice.ledger_entries.count }
      upfront_invoice.should_not be_acknowledged_expense
      Timecop.return
    end
    
    it 'does not do anything if the subscription is paid in due-month' do
      Billingly::Customer.any_instance.stub(ledger: {cash: 500})
      invoice.settle
      expect do
        invoice.acknowledge_expense
      end.not_to change{ invoice.ledger_entries.count }
      invoice.should_not be_acknowledged_expense
    end
    
    it 'does not acknowledge the expense twice' do
      Billingly::Customer.any_instance.stub(ledger: {cash: 500})
      customer = upfront_invoice.customer
      upfront_invoice.settle
      Timecop.travel(1.year.from_now + 1.day)
      upfront_invoice.acknowledge_expense

      expect do
        upfront_invoice.acknowledge_expense
      end.not_to change{ upfront_invoice.ledger_entries.count }
      
      Timecop.return
    end
  end
  
  it 'Acknowledges expenses for all invoices that have not been acknowledged yet' do
    Billingly::Customer.any_instance.stub(ledger: {cash: 200})
    invoice = create(:first_year).invoices.first
    2.times{ create(:first_year, customer: create(:customer)) }
    Billingly::Invoice.all.each {|i| i.settle }
    
    Timecop.travel 370.days.from_now
    invoice.reload
    invoice.acknowledge_expense
    
    expect do
      Billingly::Invoice.acknowledge_expenses
    end.to change{ Billingly::Invoice.where(acknowledged_expense: nil).count }.by(-2)

    Timecop.return
  end
  
  it 'should be able to forfeit invoices' do
    pending
  end
  
end
