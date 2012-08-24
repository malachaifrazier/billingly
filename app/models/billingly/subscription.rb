module Billingly
  class Subscription < ActiveRecord::Base
    has_many :ledger_entries
    # If a subscription is payable_upfront, then the customer effectively owes us
    # since the day in which a given period starts.
    # If a subscription is payable on 'due-month', then the customer effectively
    # owes us money since the date in which a given period ended.
    # When we invoice for a given period we will set the due_date a few days
    # ahead of the date in which the debt was made effective, we call this
    # a GRACE_PERIOD.
    GRACE_PERIOD = 10.days
    
    # Invoices will be generated before their due_date, as soon as possible,
    # but not sooner than GENERATE_AHEAD days.
    GENERATE_AHEAD = 15.days

    # Subscriptions are to be charged periodically. Their periodicity is
    # stored semantically on the database, but we want to convert it
    # to actual ruby time ranges to do date arithmetic.
    PERIODICITIES = {'monthly' => 1.month, 'yearly' => 1.year}

    belongs_to :customer
    has_many :invoices
   
    validates :periodicity, inclusion: PERIODICITIES.keys

    # The periodicity can be set using a symbol, for convenience.
    # It's still a string under the hood.
    def periodicity=(value)
      self[:periodicity] = value.to_s if value
    end
    
    def period_size
      case periodicity
      when 'monthly' then 1.month
      when 'yearly' then 1.year
      else
        raise ArgumentError.new 'Cannot get period size without periodicity'
      end 
    end
    
    # The invoice generation process should run frequently, at least on a daily basis.
    # It will create invoices some time before they are due, to give customers a chance
    # to pay and settle them.
    # This method is idempotent, if an upcoming invoice for a subscription already exists,
    # it does not create yet another one.
    def generate_next_invoice
      return if unsubscribed_on
      from = invoices.empty? ? subscribed_on : invoices.last.period_end
      to = from + period_size
      due_on = (payable_upfront ? from : to) + GRACE_PERIOD
      return unless DateTime.now + GENERATE_AHEAD > due_on

      invoice = invoices.create!(customer: customer, amount: amount,
        due_on: due_on, period_start: from, period_end: to)
      

      # when generating an upfront invoice the ledger should register a
      # commitment between the service we will provide and the money we will
      # receive.
      # In case of a due-month payment the service was already provide so we 
      # register a debt and an expense.
      accounts = payable_upfront ? %w(ioweyou services_to_provide) : %w(expenses debt)

      accounts.each do |account|
        ledger_entries.create!(customer: customer, account: account,
          invoice: invoice, amount: amount ) 
      end

      return invoice
    end
    
  end
end
