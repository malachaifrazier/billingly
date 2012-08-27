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
      expect do
        receipt = invoice.settle
        %w(debt cash).each do |account|
          receipt.ledger_entries.find_by_account(account).tap do |l|
            l.should_not be_nil
            l.amount.to_f.should == -(invoice.amount)
            l.receipt.should == receipt
            l.invoice.should be_nil
            l.payment.should be_nil
            l.customer == customer 
          end
        end
      end.to change{ customer.ledger_entries.count }.by(2)
    end

    it 'creates ledger entries for a subscription that was paid upfront' do
      Billingly::Customer.any_instance.stub(ledger: {cash: 500})
      customer = upfront_invoice.customer
      expect do
        receipt = upfront_invoice.settle
        %w(paid_upfront cash services_to_provide ioweyou).each do |account|
          receipt.ledger_entries.find_by_account(account).tap do |l|
            l.should_not be_nil
            l.receipt.should == receipt
            l.invoice.should be_nil
            l.payment.should be_nil
            l.customer == customer 
          end
        end
        %w(ioweyou cash services_to_provide).each do |account|
          receipt.ledger_entries.find_by_account(account).tap do |l|
            l.amount.to_f.should == -(upfront_invoice.amount.to_f)
          end
        end
        receipt.ledger_entries.find_by_account('paid_upfront')
          .amount.to_f.should == upfront_invoice.amount.to_f
      end.to change{ customer.ledger_entries.count }.by(4)
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
      upfront_invoice.settle

      Timecop.travel(1.year.from_now + 1.day)

      expect do
        upfront_invoice.acknowledge_expense
        %w(expenses paid_upfront).each do |account|
          upfront_invoice.ledger_entries.find_by_account(account).tap do |l|
            l.should_not be_nil
            l.receipt.should be_nil
            l.invoice.should == upfront_invoice
            l.customer == upfront_invoice.customer 
          end
        end

        upfront_invoice.ledger_entries.where(account:'paid_upfront').last
          .amount.to_f.should == -(upfront_invoice.amount.to_f)

        upfront_invoice.ledger_entries.where(account:'expenses').last
          .amount.to_f.should == upfront_invoice.amount.to_f

      end.to change{ upfront_invoice.ledger_entries.count }.by(2)

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
      Timecop.travel 370.days.from_now
      invoice.should be_acknowledged_expense
      expect do
        invoice.acknowledge_expense
      end.not_to change{ invoice.ledger_entries.count }
      Timecop.return
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
    2.times{ create(:first_year, customer: Billingly::Customer.create!(customer_since: 1.day.ago)) }
    Billingly::Invoice.all.each {|i| i.settle }
    
    Timecop.travel 370.days.from_now
    invoice.reload
    invoice.acknowledge_expense
    
    expect do
      Billingly::Invoice.acknowledge_expenses
    end.to change{ Billingly::Invoice.where(acknowledged_expense: nil).count }.by(-2)

    Timecop.return
  end
end
