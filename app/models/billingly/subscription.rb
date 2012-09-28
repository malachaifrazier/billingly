module Billingly
  require 'has_duration'
 
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

    # The date in which this subscription started.
    # This subscription's first invoice will have it's period_start date
    # matching the date in which the subscription started.
    # @property subscribed_on
    # @return [DateTime]
    validates :subscribed_on, presence: true

    # The grace period we use when calculating an invoices due date.
    # If a subscription is payable_upfront, then the customer effectively owes us
    # since the day in which a given period starts.
    # If a subscription is payable on 'due-month', then the customer effectively
    # owes us money since the date in which a given period ended.
    # When we invoice for a given period we will set the due_date a few days
    # ahead of the date in which the debt was made effective, we call this
    # a grace_period.
    # @property grace_period
    # @return [ActiveSupport::Duration] It's what you get by doing '1.month', '10.days', etc.
    has_duration :grace_period
    validates :grace_period, presence: true
    
    # A subscription can be a free trial, ending on the date stored in `is_trial_expiring_on'.
    # Free trial subscriptions don't have {Invoice invoices}. The {Customer customer} is required
    # to subscribe to a non-trial plan before the trial subscription expires.
    #
    # The {#trial?} convenience method returns wheter this subscription is a trial or not.
    #
    # @property is_trial_expiring_on
    # @return [DateTime] 
    
    # When a subscription was started from a {Plan} a reference to the plan is saved.
    # Although, all the plan's fields are denormalized in this subscription.
    #
    # If the subscription was not started from a plan, then this will be nil.
    #
    # @property plan
    # @return [Billingly::Plan, nil] 
    belongs_to :plan
    
    # (see #is_trial_expiring_on)
    # @property trial?
    # @return [Boolean]
    def trial?
      not is_trial_expiring_on.nil?
    end

    # Invoices will be generated before their due_date, as soon as possible,
    # but not sooner than GENERATE_AHEAD days.
    GENERATE_AHEAD = 3.days

    belongs_to :customer
    has_many :invoices
   
    has_duration :periodicity
    validates :periodicity, presence: true

    # The invoice generation process should run frequently, at least on a daily basis.
    # It will create invoices some time before they are due, to give customers a chance
    # to pay and settle them.
    # This method is idempotent, if an upcoming invoice for a subscription already exists,
    # it does not create yet another one.
    def generate_next_invoice
      return if terminated?
      return if trial?
      from = invoices.empty? ? subscribed_on : invoices.last.period_end
      to = from + periodicity
      due_on = (payable_upfront ? from : to) + grace_period
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
      invoices.last.truncate unless trial?
      return self
    end
    
    def terminated?
      not unsubscribed_on.nil?
    end
    
    # This class method is called from a cron job, it creates invoices for all the subscriptions
    # that still need their invoice created.
    # TODO: This goes through all the active subscriptions, make it smarter so that the batch job runs quicker.
    def self.generate_next_invoices
      where(is_trial_expiring_on: nil, unsubscribed_on: nil).each do |subscription|
        subscription.generate_next_invoice
      end
    end
  end
end
