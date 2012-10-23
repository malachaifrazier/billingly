require 'spec_helper'

describe Billingly::Subscription do
  describe 'when invoicing' do
    describe 'when generating the first invoice' do
      let(:subscription){ create(:customer).subscribe_to_plan(build(:pro_50_monthly)) }
      subject{ subscription.invoices.last }

      its(:paid_on){ should be_nil }
      its(:amount){ should == 9.9 }
      its(:customer){ should == subscription.customer }
      its(:period_end){ should == subscription.subscribed_on + 1.month }

      it 'starts invoicing from the time the subscription started' do
        subject.period_start.should == subscription.subscribed_on
      end
    end
    
    it 'does not generate invoices too far in advance' do
      subscription = create(:first_month)
      expect do
        subscription.generate_next_invoice.should be_nil
      end.not_to change{ subscription.invoices.count }
    end
    
    it 'generates an invoice a few days before the period the period it covers starts' do
      subscription = create(:first_month)
      Timecop.travel 29.days.from_now
      expect do
        subscription.generate_next_invoice.should_not be_nil
      end.to change{ subscription.invoices.count }.by(1)
      Timecop.return
    end
    
    it 'generates invoices if they are missing and the period they cover has started' do
      subscription = create(:first_month)
      Timecop.travel 35.days.from_now
      expect do
        subscription.generate_next_invoice.should_not be_nil
      end.to change{ subscription.invoices.count }.by(1)
      Timecop.return
    end

    it 'creates new invoices for the period starting when the previous period ended' do
      subscription = create(:fourth_month)
      old_end = subscription.invoices.last.period_end
      expect do
        invoice = subscription.generate_next_invoice
        invoice.period_start.should == old_end
      end.to change{ subscription.invoices.count }.by(1)
    end
    
    it 'should not generate an invoice for a terminated subscription' do
      subscription = create(:expired_trial)
      expect do
        subscription.generate_next_invoice.should be_nil
      end.not_to change{ subscription.invoices.count }
    end

    it 'should try to charge the newly created invoice right away too' do
      subscription = create(:fourth_month)
      Billingly::Invoice.any_instance.should_receive(:charge).once
      subscription.generate_next_invoice
      expect do
        subscription.generate_next_invoice.should be_nil
      end.not_to change{ Billingly::Invoice.count }
    end
    
  end

  it 'sets the right due date for the first yearly upfront invoices' do
    subscription = create(:yearly, subscribed_on: Date.today)
    subscription.generate_next_invoice.due_on.to_date.should ==
        (subscription.subscribed_on.to_date + subscription.grace_period)
  end

  it 'sets the right due date for the first monthly due-month invoice' do
    subscription = create(:monthly, subscribed_on: Date.today)
    first_invoice = subscription.generate_next_invoice
    first_invoice.due_on.to_date.should ==
        (subscription.subscribed_on + 1.month + subscription.grace_period).to_date
  end
  
  describe 'when terminating a subscription' do
    it 'sets the unsubscribed_on date' do
      subscription = create(:first_month)
      subscription.terminate_left_voluntarily
      subscription.unsubscribed_on.utc.to_s.should == Time.now.utc.to_s
    end
    
    it 'truncates invoices' do
      subscription = create(:first_month)
      first_invoice = subscription.generate_next_invoice
      Billingly::Invoice.any_instance.should_receive(:truncate)
      subscription.terminate_debtor
    end
    
    it 'does not terminate an already terminated subscription' do
      subscription = create(:first_month)
      subscription.terminate_debtor.should_not be_nil
      subscription.terminate_debtor.should be_nil
    end
    
    it 'validates terminated subscriptions have a deactivation reason' do
      subscription = build(:first_month, unsubscribed_on: Time.now)
      subscription.should_not be_valid
      subscription.errors.should have_key(:unsubscribed_because)
    end
    
    it 'validates that subscription with an unsubscribed_before have an unsubscribed_on date' do
      subscription = build(:first_month, unsubscribed_because: :debtor)
      subscription.should_not be_valid
      subscription.errors.should have_key(:unsubscribed_on)
    end

    it 'is valid if both unsubscribed date and reason are empty' do
      build(:first_month).should be_valid
    end

    it 'validates the unsubscribed reason to be one of the preset ones' do
      build(:first_month, unsubscribed_on: Time.now, unsubscribed_because: :bogus)
        .should_not be_valid
    end

    %w(trial_expired debtor changed_subscription left_voluntarily).each do |reason|
      it "has a shortcut for terminating using #{reason}" do
        subscription = create(:first_year).send("terminate_#{reason}")
        subscription.should_not be_nil
        subscription.unsubscribed_because.should == reason
      end
    end
  end
  
  describe 'when doing a trial period' do
    it 'Exposes a trial attribute' do
      create(:trial).should be_trial
      create(:first_month).should_not be_trial
    end

    it 'should never generate an invoice for a trial subscription' do
      subscription = create(:trial)
      expect do
        subscription.generate_next_invoice.should be_nil
      end.not_to change{ subscription.invoices.count }
    end
  end
  
  describe 'when notifying a finished trial period' do
    it 'notifies a trial that has expired' do
      trial = create(:expired_trial)
      expect do
        trial.notify_trial_expired.should_not be_nil
      end.to change{ ActionMailer::Base.deliveries.size }.by(1)
    end
    
    it 'only notifies trial periods which have expired' do
      trial = create(:trial)
      expect do
        trial.notify_trial_expired.should be_nil
      end.not_to change{ ActionMailer::Base.deliveries.size }
    end

    it 'does not notify subscriptions which are not trials' do
      subscription = create(:first_month)
      Timecop.travel 2.months.from_now
      expect do
        subscription.notify_trial_expired.should be_nil
      end.not_to change{ ActionMailer::Base.deliveries.size }
      subscription.notified_trial_expired_on.should be_nil
    end
    
    it 'does not notify if customer is not deactivated b/c of trial_expired' do
      trial = create(:abandoned_trial)
      expect do
        trial.notify_trial_expired.should be_nil
      end.not_to change{ ActionMailer::Base.deliveries.size }
    end
    
    it 'does not notify if already notified' do
      trial = create(:expired_trial)
      trial.notify_trial_expired.should_not be_nil
      expect do
        trial.notify_trial_expired.should be_nil
      end.not_to change{ ActionMailer::Base.deliveries.size }
    end

    it 'does not notify if customer opted out of emails' do
      Billingly::Customer.any_instance.stub(do_not_email?: true)
      trial = create(:expired_trial)
      expect do
        trial.notify_trial_expired.should be_nil
      end.not_to change{ ActionMailer::Base.deliveries.size }
    end
  end
end
