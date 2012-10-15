module SpecHelpers
  def assert_ledger(customer, expectations = {})
    customer.reload
    customer.ledger.each do |key, value|
      expectations[key] ||= 0.0
    end
    customer.ledger.should == expectations
  end
    
  def should_add_to_journal(customer, new_count, &blk)
    expect(&blk).to change{ customer.journal_entries.count }.by(new_count)
  end

  def should_have_journal_entries(customer, amount, *accounts, extra)
    customer.reload
    accounts = [] if accounts.nil?
    unless extra.is_a?(Hash)
      accounts << extra
      extra = {}
    end
    
    accounts.each do |account|
      entry = customer.journal_entries.where(
        account: account.to_s,
        invoice_id: extra[:invoice],
        payment_id: extra[:payment],
        subscription_id: extra[:subscription]
      ).last
      entry.should_not be_nil
      entry.amount.to_f.should == amount.to_f
    end
  end
  
  def days_go_by(days=1)
    Billingly::Tasks.new.run_all
    Timecop.travel (days/2).days.from_now
    Billingly::Tasks.new.run_all
    Timecop.travel (days/2).days.from_now
    Billingly::Tasks.new.run_all
  end
  
  def should_email(email_method)
    Billingly::Mailer.should_receive(email_method) do |arg|
      double(deliver!: true)
    end
  end

  def should_not_email(email_method)
    Billingly::Mailer.should_not_receive(email_method)
  end
end
