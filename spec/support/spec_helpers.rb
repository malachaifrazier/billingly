module SpecHelpers
  def assert_ledger(customer, expectations = {})
    customer.reload
    customer.ledger.each do |key, value|
      expectations[key] ||= 0.0
    end
    customer.ledger.should == expectations
  end
    
  def should_add_to_ledger(customer, new_count, &blk)
    expect(&blk).to change{ customer.ledger_entries.count }.by(new_count)
  end

  def should_have_ledger_entries(customer, amount, *accounts, extra)
    customer.reload
    accounts = [] if accounts.nil?
    unless extra.is_a?(Hash)
      accounts << extra
      extra = {}
    end
    
    accounts.each do |account|
      entry = customer.ledger_entries.where(
        account: account.to_s,
        receipt_id: extra[:receipt],
        invoice_id: extra[:invoice],
        payment_id: extra[:payment],
        subscription_id: extra[:subscription]
      ).last
      entry.should_not be_nil
      entry.amount.to_f.should == amount.to_f
    end
  end
  
  def days_go_by(days=1)
    do_all = lambda do
      Billingly::Subscription.generate_next_invoices
      Billingly::Invoice.charge_all
      Billingly::Customer.deactivate_all_debtors
      Billingly::Invoice.notify_all_paid
      Billingly::Invoice.notify_all_pending
      Billingly::Invoice.notify_all_overdue
    end
    do_all.call
    Timecop.travel (days/2).days.from_now
    do_all.call
    Timecop.travel (days/2).days.from_now
    do_all.call
  end
  
  def should_email(email_method)
    BillinglyMailer.should_receive(email_method) do |arg|
      double(deliver!: true)
    end
  end

  def should_not_email(email_method)
    BillinglyMailer.should_not_receive(email_method)
  end
end
