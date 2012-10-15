require 'spec_helper'

describe Billingly::Mailer do
  it 'sends a notification about a pending invoice' do
    subscription = create(:first_month)
    subscription.customer.credit_payment(5.0)
    mail = Billingly::Mailer.pending_notification(subscription.invoices.last)
    mail.to.should == [subscription.customer.email]
  end
  
  it 'sends a notification about an overdue invoice' do
    subscription = create(:first_month)
    mail = Billingly::Mailer.overdue_notification(subscription.invoices.last)
    mail.to.should == [subscription.customer.email]
  end
  
  it 'sends a notification about a paid invoice' do
    subscription = create(:first_month)
    subscription.customer.credit_payment(100.0)
    mail = Billingly::Mailer.paid_notification(subscription.invoices.last)
    mail.to.should == [subscription.customer.email]
  end

  it 'sends an email about an expired trial' do
    subscription = create(:expired_trial)
    mail = Billingly::Mailer.trial_expired_notification(subscription)
    mail.body.should =~ /Your trial period has ended/
  end
  
  it 'sends a report with the billingly tasks result' do
    runner = Billingly::Tasks.new
    runner.summary = 'All was done'
    runner.extended = 'It was all done'
    runner.started = 10.minutes.ago
    runner.ended = Time.now
    mail = Billingly::Mailer.task_results(runner)
    mail.to.should == ['admin@example.com']
    mail.body.should =~ /All was done/
    mail.body.should =~ /Started on/
    mail.body.should =~ /ended on/
  end
end
