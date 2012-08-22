class CreateBillingTables < ActiveRecord::Migration
  def self.up
    create_table :customers do |t|
      t.datetime 'customer_since', null: false
      #t.decimal 'balance', precision: 11, scale: 2, default: 0.0, null: false
    end
    
    create_table :invoices do |t|
      t.references :customer, null: false
      t.references :receipt
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
      t.references :charge
      t.string :kind # (:payment_request, :income) vs (:balance, :expense)
      t.decimal 'amount', precision: 11, scale: 2, default: 0.0, null: false
    end
    
    create_table :charges do |t|
      t.references :customer, null: false
      t.string 'name'
      t.string 'kind' # one-time, subscription.
      t.datetime 'started_using_on', null: false
      t.datetime 'stopped_using_on'
      t.decimal 'price', precision: 11, scale: 2, default: 0.0, null: false # means daily_price for subscription.
    end
  end
  
  def self.down
    drop_table :invoice
    drop_table :invoice_item
    drop_table :usage
    drop_table :payment
    drop_table :customer
  end
end

