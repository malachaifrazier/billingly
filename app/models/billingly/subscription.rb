module Billingly
  
  # A customer will always have at least one subscription to your application.
  # Everytime there is a change in a {Customer customer's} subscription, the current one
  # is terminated immediately and a new one is created.
  #
  # For example, changing a {Plan} consists on terminating the current
  # subscription and creating a new one for the new plan.
  # Also, a new subscription is created when {Customer customers} reactivate their accounts
  # after being deactivated.
  #
  # The most recent subscription is the one currently being charged for, unless the customer
  # is deactivated at the moment, in which case the last subscription should not be considered
  # to be active.
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
    GENERATE_AHEAD = 3.days

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
      return if terminated?
      from = invoices.empty? ? subscribed_on : invoices.last.period_end
      to = from + period_size
      due_on = (payable_upfront ? from : to) + GRACE_PERIOD
      return if GENERATE_AHEAD.from_now < from

      invoice = invoices.create!(customer: customer, amount: amount,
        due_on: due_on, period_start: from, period_end: to)
      invoice.charge
      return invoice
    end
    
    # Terminates this subscription, it could be either because we deactivate a debtor
    # or because the customer decided to end his subscription on his own terms.
    def terminate
      return if terminated?
      update_attribute(:unsubscribed_on, Time.now)
      invoices.last.truncate
      return self
    end
    
    def terminated?
      not unsubscribed_on.nil?
    end
    
    # This class method is called from a cron job, it creates invoices for all the subscriptions
    # that still need their invoice created.
    # TODO: This goes through all the active subscriptions, make it smarter so that the batch job runs quicker.
    def self.generate_next_invoices
      where(unsubscribed_on: nil).each do |subscription|
        subscription.generate_next_invoice
      end
    end
  end
end
