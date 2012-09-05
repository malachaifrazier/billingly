# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20120905212012) do

  create_table "billingly_customers", :force => true do |t|
    t.datetime "deactivated_since"
    t.string   "email",             :null => false
  end

  create_table "billingly_invoices", :force => true do |t|
    t.integer  "customer_id",                                                         :null => false
    t.integer  "receipt_id"
    t.integer  "subscription_id"
    t.decimal  "amount",              :precision => 11, :scale => 2, :default => 0.0, :null => false
    t.datetime "due_on",                                                              :null => false
    t.datetime "period_start",                                                        :null => false
    t.datetime "period_end",                                                          :null => false
    t.datetime "deleted_on"
    t.datetime "notified_pending_on"
    t.datetime "notified_overdue_on"
    t.datetime "notified_paid_on"
    t.text     "comment"
    t.datetime "created_at",                                                          :null => false
    t.datetime "updated_at",                                                          :null => false
  end

  create_table "billingly_ledger_entries", :force => true do |t|
    t.integer  "customer_id",                                                     :null => false
    t.string   "account",                                                         :null => false
    t.decimal  "amount",          :precision => 11, :scale => 2, :default => 0.0, :null => false
    t.integer  "subscription_id"
    t.integer  "invoice_id"
    t.integer  "payment_id"
    t.integer  "receipt_id"
    t.datetime "created_at",                                                      :null => false
    t.datetime "updated_at",                                                      :null => false
  end

  create_table "billingly_payments", :force => true do |t|
    t.integer "customer_id",                                                 :null => false
    t.decimal "amount",      :precision => 11, :scale => 2, :default => 0.0, :null => false
  end

  create_table "billingly_plans", :force => true do |t|
    t.string   "name"
    t.string   "description"
    t.string   "periodicity"
    t.decimal  "amount",          :precision => 11, :scale => 2, :default => 0.0, :null => false
    t.boolean  "payable_upfront"
    t.datetime "created_at",                                                      :null => false
    t.datetime "updated_at",                                                      :null => false
  end

  create_table "billingly_receipts", :force => true do |t|
    t.integer  "customer_id", :null => false
    t.datetime "paid_on"
    t.datetime "created_at",  :null => false
    t.datetime "updated_at",  :null => false
  end

  create_table "billingly_subscriptions", :force => true do |t|
    t.integer  "customer_id",                                                       :null => false
    t.string   "description",                                                       :null => false
    t.datetime "subscribed_on",                                                     :null => false
    t.string   "periodicity",                                                       :null => false
    t.decimal  "amount",          :precision => 11, :scale => 2, :default => 0.0,   :null => false
    t.datetime "unsubscribed_on"
    t.boolean  "payable_upfront",                                :default => false, :null => false
    t.datetime "created_at",                                                        :null => false
    t.datetime "updated_at",                                                        :null => false
  end

end
