desc """
Run all periodic billing tasks like generating new invoices,
deactivating debtors, and emailing.
You can run it as often as you want.
"""
namespace :billingly do
  task all: :environment do
    Billingly::Tasks.new.run_all
  end
  
  task export_special_plan_codes: :environment do
    puts 'Exporting your codes to CSV files...'
    Billingly::SpecialPlanCode.export_codes
    puts 'Done! CSV files with all the non-redeemed codes were created in your home directory'
  end
end
