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
      subscription = create(:fourth_month, unsubscribed_on: 1.day.ago)
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
    it 'sets the terminated_on date' do
      subscription = create(:first_month)
      subscription.terminate
      subscription.unsubscribed_on.utc.to_s.should == Time.now.utc.to_s
    end
    
    it 'truncates invoices' do
      subscription = create(:first_month)
      first_invoice = subscription.generate_next_invoice
      Billingly::Invoice.any_instance.should_receive(:truncate)
      subscription.terminate
    end
    
    it 'does not terminate an already terminated subscription' do
      subscription = create(:first_month)
      subscription.terminate.should_not be_nil
      subscription.terminate.should be_nil
    end
  end
  
  it 'generates invoices for all the subscriptions that do not have their next invoice yet' do
    3.times{ create(:first_month, customer: create(:customer)) }
    
    Timecop.travel 1.month.from_now

    Billingly::Subscription.first.generate_next_invoice
    
    expect do
      Billingly::Subscription.generate_next_invoices
    end.to change{ Billingly::Invoice.count }.by(2)
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
end
