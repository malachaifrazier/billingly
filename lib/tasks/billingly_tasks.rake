desc """
Run all periodic billing tasks like generating new invoices,
deactivating debtors, and emailing.
You can run it as often as you want.
"""
namespace :billingly do
  task all: :environment do
    puts 'Generating invoices'
    Billingly::Subscription.generate_next_invoices
    puts 'Charging invoices if possible'
    Billingly::Invoice.charge_all
    puts 'Deactivating debtors'
    Billingly::Customer.deactivate_all_debtors
    puts 'Sending payment receipts'
    Billingly::Invoice.notify_all_paid
    puts 'Notifying pending invoices'
    Billingly::Invoice.notify_all_pending
    puts 'Notifying deactivated debtors'
    Billingly::Invoice.notify_all_overdue
  end
end
