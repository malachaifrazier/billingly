# This spec checks that the recurring task runs as expected and logs
# errors accordingly.
require 'spec_helper'

describe Billingly::Tasks do
  describe 'when running all tasks' do
    it 'sends an email with the results' do
      runner = Billingly::Tasks.new
      Billingly::Mailer.should_receive(:task_results).with(runner){ double(deliver: true) }
      runner.run_all
    end

    describe 'when setting local variables' do
      subject do
        Billingly::Tasks.new.tap do |runner|
          runner.run_all
        end
      end
      
      its(:summary){ should_not be_nil }
      its(:started){ should_not be_nil }
      its(:ended){ should_not be_nil }
    end
  end
  
  it 'writes the extended log to a file' do
    runner = Billingly::Tasks.new
    runner.log_extended("All is good")
    runner.extended.path.should =~ /#{Rails.root}\/log\/billingly_[0-9]*\.log/
    runner.extended.close
    File.open(runner.extended.path,'r').read.should == "All is good\n\n"
    `rm #{Rails.root}/log/billingly_*`
  end

  describe 'when generating the next invoices' do
    it 'generates invoices for all the subscriptions that do not have their next invoice yet' do
      3.times{ create(:first_month, customer: create(:customer)) }
      Timecop.travel 1.month.from_now
      Billingly::Subscription.first.generate_next_invoice
      expect do
        Billingly::Tasks.new.generate_next_invoices
      end.to change{ Billingly::Invoice.count }.by(2)
    end
  
    it 'Shows an all-ok summary' do
      3.times{ create(:first_month, customer: create(:customer)) }
      Timecop.travel 1.month.from_now
      runner = Billingly::Tasks.new
      runner.should_not_receive(:log_extended)
      runner.generate_next_invoices
      runner.summary.should == "Success: Generating Invoices, 3 OK.\n"
    end
    
    it 'Shows a summary with errors and logs exceptions in the exception log' do
      3.times{ create(:first_month, customer: create(:customer)) }
      Timecop.travel 1.month.from_now
      first = true
      Billingly::Subscription.any_instance.stub(:generate_next_invoice) do
        if first
          first = false
          raise 'error'
        end
        true
      end
      
      runner = Billingly::Tasks.new
      runner.should_receive(:log_extended).once
      runner.generate_next_invoices
      runner.summary.should == "Failure: Generating Invoices, 2 OK, 1 failed.\n"
    end
  end
  
  describe 'when batch charging invoices' do
    it 'should charge all unpaid invoices' do
      Billingly::Customer.any_instance.stub(ledger: {cash: 300})
      3.times{ create(:first_month, customer: create(:customer)) }
      Billingly::Invoice.first.charge

      expect do
        Billingly::Tasks.new.charge_invoices
      end.to change{ Billingly::Invoice.where(paid_on: nil).count }.by(-2)
    end
    
    it 'should not settle invoice if customer does not have enough money in balance' do
      create(:first_month)
      expect do
        Billingly::Tasks.new.charge_invoices
      end.not_to change{ Billingly::Invoice.where(paid_on: nil).count }
    end
  end

  describe 'when notifying pending invoices' do
    it 'notifies all pending invoices' do
      create(:first_month) # This one is not due until a month from now
      invoice = create(:first_year).invoices.last # This one should be invoiced as it is due soon
      expect do
        Billingly::Tasks.new.notify_all_pending
      end.to change{ ActionMailer::Base.deliveries.count }.by(1)
      invoice.reload
      invoice.notified_pending_on.should_not be_nil
      Billingly::Invoice
        .where(paid_on: nil, notified_pending_on: nil)
        .where('due_on < ?', 20.days.from_now).count.should == 0
    end
  end

  describe 'when notifying overdue invoices' do
    it 'notifies all overdue invoices' do
      create(:first_month) # This one is not due until a month from now
      invoice = create(:first_year).invoices.last # This one should be invoiced as it is due soon
      Timecop.travel 20.days.from_now
      expect do
        Billingly::Tasks.new.notify_all_overdue
      end.to change{ ActionMailer::Base.deliveries.count }.by(1)
      invoice.reload
      invoice.notified_overdue_on.should_not be_nil
      Billingly::Invoice
        .where(paid_on: nil, notified_overdue_on: nil)
        .where('due_on < ?', Time.now).count.should == 0
    end
  end

  describe 'when notifying paid invoices' do
    it 'notifies all paid invoices' do
      invoice = create(:first_year).invoices.first # This one should be paid
      create(:first_year, customer: create(:customer)) 
      invoice.customer.credit_payment(100.0)
      expect do
        Billingly::Tasks.new.notify_all_paid
      end.to change{ ActionMailer::Base.deliveries.count }.by(1)
      invoice.reload
      invoice.notified_paid_on.should_not be_nil
      Billingly::Invoice
        .where('paid_on IS NOT NULL AND notified_paid_on IS NULL').count.should == 0
    end
  end

  describe 'deactivating a debtors' do
    it 'mass deactivates customers who missed a due-date' do
      subscription = create(:first_year, :overdue)

      expect do
        expect do
          Billingly::Tasks.new.deactivate_all_debtors
          subscription.reload
        end.to change{ subscription.terminated? }
      end.to change{ subscription.customer.deactivated? }

      subscription.customer.deactivated_since.utc.to_s.should == Time.now.utc.to_s
      subscription.customer.deactivation_reason.should == 'debtor'
    end
  
    it 'does not mass re-deactivate already deactivated debtors' do
      subscription = create(:first_year, :overdue, :deactivated)
      expect do
        expect do
          Billingly::Tasks.new.deactivate_all_debtors
          subscription.reload
        end.not_to change{ subscription.terminated? }
      end.not_to change{ subscription.customer.deactivated? }
    end
  end
  
  describe 'when deactivating trials' do
    it 'deactivates overdue trials' do
      one = create(:trial, is_trial_expiring_on: 10.days.ago)
      two = create(:trial, customer: create(:customer))
      three = create(:trial, is_trial_expiring_on: 10.days.ago, customer: create(:customer))
      three.customer.subscribe_to_plan(build(:pro_50_monthly))
      Billingly::Tasks.new.deactivate_all_expired_trials
      one.reload
      two.reload
      three.reload
      one.customer.should be_deactivated
      one.customer.deactivation_reason.should == 'trial_expired'
      two.customer.should_not be_deactivated
      three.customer.should_not be_deactivated
    end
  end
end
