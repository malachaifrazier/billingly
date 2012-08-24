class CreateBillinglyTables < ActiveRecord::Migration
  def self.up
    create_table :customers do |t|
      t.datetime 'customer_since', null: false
    end
    
    create_table :invoices do |t|
      t.references :customer, null: false
      t.references :receipt
      t.references :subscription
      t.decimal 'amount', precision: 11, scale: 2, default: 0.0, null: false
      t.datetime 'due_on', null: false
      t.datetime 'period_start', null: false
      t.datetime 'period_end', null: false
      t.text 'comment'
      t.timestamps
    end

    create_table :payments do |t|
      t.references :customer, null: false
      t.decimal 'amount', precision: 11, scale: 2, default: 0.0, null: false
    end
    
    create_table :receipts do |t|
      t.references :customer, null: false
      t.datetime 'paid_on'
      t.timestamps
    end

    create_table :ledger_entries do |t|
      t.references :customer, null: false
      t.references :invoice
      t.references :payment
      t.references :receipt
      t.references :subscription
      # Assets and expenses:
      #   cash
      #   expense
      #   ioweyou
      #   paid_upfront
      #   
      # Debt and income:
      #   debt
      #   income
      #   services_to_provide
      #   
      t.string :account
      t.decimal 'amount', precision: 11, scale: 2, default: 0.0, null: false
      t.timestamps
    end
    
    create_table :one_time_charges do |t|
      t.references :customer, null: false
      t.decimal 'amount', precision: 11, scale: 2, default: 0.0, null: false
      t.string 'description', null: false
      t.datetime 'charge_on', null: false
      t.timestamps
    end
    
    create_table :subscriptions do |t|
      t.references :customer, null: false
      t.string 'description', null: false
      t.datetime 'subscribed_on', null: false
      t.string 'periodicity', null: false
      t.decimal 'amount', precision: 11, scale: 2, default: 0.0, null: false
      t.datetime 'expires_on'
      t.datetime 'unsubscribed_on'
      t.boolean 'payable_upfront', null: false, default: false
      t.timestamps
    end
    
    create_table :plans do |t|
      t.string 'name' # Pro 50
      t.string 'description' # 50GB for 9,99 a month.
      t.string 'periodicity'
      t.decimal 'amount', precision: 11, scale: 2, default: 0.0, null: false # 9.99
      t.boolean 'payable_upfront' # true
      t.timestamps
    end
      
  end
  
  def self.down
  end
end

