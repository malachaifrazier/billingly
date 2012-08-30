require 'spec_helper'

describe Billingly::Invoice do
  let(:invoice){ create(:fourth_month).invoices.last }
  
  it 'is deemed paid when there is a receipt associated to it' do
    invoice.should_not be_paid
    invoice.create_receipt(customer: invoice.customer, paid_on: Time.now)
    invoice.should be_paid
  end
  
  describe 'when charging an invoice' do
    it 'generates a receipt' do
      Billingly::Customer.any_instance.stub(ledger: {cash: 500})
      invoice.receipt.should be_nil
      invoice.charge.should_not be_nil
      invoice.receipt.should_not be_nil
    end
    
    it 'does not attempt to charge if already charged' do
      Billingly::Customer.any_instance.stub(ledger: {cash: 500})
      invoice.charge
      invoice.should be_paid
      invoice.charge.should be_nil
    end
    
    it 'does not attempt to charge deleted invoices' do
      invoice.update_attribute(:deleted_on, Time.now)
      invoice.charge.should be_nil
      invoice.should_not be_paid
    end

    it 'does not charge if customer cash balance is not enough' do
      Billingly::Customer.any_instance.stub(ledger: {cash: 0})
      invoice.charge.should be_nil
      invoice.should_not be_paid
    end

    it 'increases expenses and reduces the cash balance when charging' do
      Billingly::Customer.any_instance.stub(ledger: {cash: 200})
      customer = invoice.customer
      should_add_to_ledger(customer, 2) do
        receipt = invoice.charge
        extra = {receipt: receipt, subscription: invoice.subscription}
        should_have_ledger_entries(customer, -(invoice.amount), :cash, extra)
        should_have_ledger_entries(customer, invoice.amount, :expenses, extra)
      end
    end
  end
  
  describe 'when truncating an invoice' do
    let(:invoice){ create(:first_year).invoices.first }

    it 'changes the end of the period covered' do
      invoice.truncate
      invoice.period_end.utc.to_s.should == Time.now.utc.to_s
    end

    it 'prorates and changes its price' do
      Timecop.travel 6.months.from_now
      invoice.truncate
      invoice.amount.to_f.should == 50.0
      Timecop.return
    end

    it 'reimburses money to the user balance if already paid' do
      customer = invoice.customer
      customer.add_to_ledger(100.0, :cash, :income)
      receipt = invoice.charge
      Timecop.travel 6.months.from_now
      should_add_to_ledger(customer, 2) do
        invoice.truncate
        extra = {invoice: invoice, subscription: invoice.subscription}
        should_have_ledger_entries(customer, -49.99, :expenses, extra)
        should_have_ledger_entries(customer, 49.99, :cash, extra)
      end
      Timecop.return
    end
    
    it 'does not reimburse anything if unpaid' do
      customer = invoice.customer
      Timecop.travel 6.months.from_now
      expect do
        invoice.truncate
        customer.reload
      end.not_to change{ customer.ledger_entries.count }
      Timecop.return
    end
    
    it 'charges the new amount, will fail if already paid' do
      Billingly::Invoice.any_instance.should_receive(:charge)
      invoice.truncate
    end
    
    it 'does not truncate invoice that cover periods that already ended' do
      Timecop.travel 2.years.from_now
      invoice.truncate.should be_nil
      Timecop.return
    end
  end

  describe 'batch charging invoices' do
    it 'should charge all unpaid invoices' do
      Billingly::Customer.any_instance.stub(ledger: {cash: 300})
      3.times{ create(:first_month, customer: create(:customer)) }
      Billingly::Invoice.first.charge

      expect do
        Billingly::Invoice.charge_all
      end.to change{ Billingly::Invoice.where(receipt_id: nil).count }.by(-2)
    end
    
    it 'should charge all unpaid invoices for a specific customer' do
      Billingly::Customer.any_instance.stub(ledger: {cash: 300})
      3.times{ create(:first_month, customer: create(:customer)) }

      expect do
        Billingly::Invoice.charge_all(Billingly::Customer.first.invoices)
      end.to change{ Billingly::Invoice.where(receipt_id: nil).count }.by(-1)
    end
    
    it 'should not settle invoice if customer does not have enough money in balance' do
      create(:first_month)
      expect do
        Billingly::Invoice.charge_all
      end.not_to change{ Billingly::Invoice.where(receipt_id: nil).count }
    end
    
    it 'should settle oldest invoice first' do
      subscription = create(:first_month)
      Timecop.travel 1.month.from_now
      oldest = subscription.invoices.first
      latest = subscription.generate_next_invoice

      # We credit the customer balance after creating the second invoice, because
      # 'generate_next_invoice' will charge it immediately otherwise.
      subscription.customer.add_to_ledger(10, :cash)
  
      Billingly::Invoice.charge_all
      oldest.reload
      oldest.should be_paid

      latest.reload
      latest.should_not be_paid
      Timecop.return
    end
  end
end
