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
    
end
