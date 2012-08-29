require 'spec_helper'

describe Billingly::LedgerEntry do
  it 'validates account is a valid name' do
    create(:customer).ledger_entries.build(amount: 100.0, account: 'invalid').should_not be_valid
  end
end
