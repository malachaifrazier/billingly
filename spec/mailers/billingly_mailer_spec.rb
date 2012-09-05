require 'spec_helper'

describe BillinglyMailer do
  it 'sends a notification about a pending invoice' do
    subscription = create(:first_month)
    subscription.customer.credit_payment(5.0)
    mail = BillinglyMailer.pending_notification(subscription.invoices.last)
    mail.to.should == [subscription.customer.email]
  end
  
  it 'sends a notification about an overdue invoice' do
    subscription = create(:first_month)
    mail = BillinglyMailer.overdue_notification(subscription.invoices.last)
    mail.to.should == [subscription.customer.email]
  end
  
  it 'sends a notification about a paid invoice' do
    subscription = create(:first_month)
    subscription.customer.credit_payment(100.0)
    mail = BillinglyMailer.paid_notification(subscription.invoices.last)
    mail.to.should == [subscription.customer.email]
  end
end
