require 'spec_helper'

describe Billingly::Subscription do
  
  { 'monthly' => true, 'yearly' => true, :yearly => true, :monthly => true,
    'invalid' => false, nil => false}.each do |value, expectation|
    it "validates periodicity '#{value}'" do
      build(:first_month, periodicity: value).valid?.should == expectation
    end
  end
  
  { :monthly => 1.month, :yearly => 1.year }.each do |value, expectation|
    it 'exposes the periodicity size to do date arithmetic' do
      build(:first_month, periodicity: value).period_size.should == expectation
    end
  end
  
  it 'should not get a period size when there is no periodicity' do
    expect do
      build(:first_month, periodicity: nil).period_size
    end.to raise_exception(ArgumentError)
  end

  describe 'when generating the next invoice' do
    describe 'when generating the first invoice for a subscription' do
      let(:subscription){ create(:first_month) }

      subject{ subscription.generate_next_invoice }
      its(:receipt){ should be_nil }
      its(:amount){ should == 9.9 }
      its(:customer){ should == subscription.customer }
      its(:period_end){ should == subscription.subscribed_on + 1.month }

      it 'starts invoicing from the time the subscription started' do
        subject.period_start.should == subscription.subscribed_on
      end

      it 'sets the right due date' do
        subject.due_on.to_date.should ==
          (subscription.created_at.to_date + Billingly::Subscription::GRACE_PERIOD)
      end
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
      end.not_to change{ Billingly::Invoice.count }
    end
    
    it 'does not generate a next invoice if last invoice has been generated already' do
      subscription = create(:fourth_month)
      subscription.generate_next_invoice
      expect do
        subscription.generate_next_invoice.should be_nil
      end.not_to change{ Billingly::Invoice.count }
    end
    
    it 'does not generate invoices if it is more than 15 days until their due date' do
      # If I subscribed exactly four months ago, and I pay on due month, my next invoice's due date
      # should be today + grace_period
      grace_period = Billingly::Subscription::GRACE_PERIOD
      heads_up = Billingly::Subscription::GENERATE_AHEAD
      subscription = create(:fourth_month)
      
      # Go back to a date in which it was too soon to generate the current invoice.
      Timecop.travel(grace_period.from_now - heads_up - 1.day)
      expect do
        subscription.generate_next_invoice.should be_nil
      end.not_to change{ Billingly::Invoice.count }
      
      # Now travel to one of the first days in which it started to be ok to generate
      # the invoice for the current period.
      Timecop.travel 2.days.from_now
      expect do
        subscription.generate_next_invoice.should_not be_nil
      end.to change{ Billingly::Invoice.count }.by(1)
      
      Timecop.return
    end
  end
end
