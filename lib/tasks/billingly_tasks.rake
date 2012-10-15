desc """
Run all periodic billing tasks like generating new invoices,
deactivating debtors, and emailing.
You can run it as often as you want.
"""
namespace :billingly do
  task all: :environment do
    Billingly::Tasks.new.run_all
  end
end
