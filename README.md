# @markup markdown

# Billingly

Billingly is a rails 3 engine that manages paid subscriptions and free trials to your web application. 

If you do SaaS then Billingly can:

* Subscribe customers to your service:
  * Subscriptions can have an arbitrary length: A year, a month, 90 days ...
  * You can request payments upfront or after the subscription period is over.

* Offer standarized subscription plans for self-service sign ups.

* Offer special deals on a per-customer basis.

* Invoice your customers automatically and send receipts once they pay.

* Notify customers about due dates.

* Restrict access to debtors, and let them back in once they pay their debt.

* Let customers upgrade or downgrade to another plan. Prorating and reimbursing in case there were any upfront payments.

* Let you give arbitrary bonuses, vouchers and gifts credited to your customer's account.

* Offer a trial period before you require people to become paying customers.

> Billingly does not receive payments directly (from Paypal, or Worldpay for example). However, you can use {http://activemerchant.org} for handling payment notifications from third party services, and easily hookup Billingly to credit the payment into your customer's account. Billingly will take care of all the rest.

## How does it work?

At it's core, billingly has a {Customer} class. A {Customer} has a {Subscription} to your service, for which she will receive {Invoice Invoices} regularly via email.
Billingly keeps a balance for each one of your {Customer customers}, whenever you receive a payment you should {Customer#credit_payment credit the payment} into their account.
When a payment is credited, billingly will try to settle outstanding invoices, always starting from the oldest one. If the customer's balance is not enough to cover the last pending invoice then nothing will happen.
Once an invoice is settled the customer will be sent a receipt via email. 
Invoices have a due date, customers will notified about pending invoices before they are overdue. When a customer misses a payment, billingly will immediately deactivate his account and notify via email about the deactivation.
Deactivated customers will be redirected forcefully to their subscription page where they can see all their invoices. Once they pay their overdue invoices their account is re-activated.
You may change a customer's subscription at any point. Doing so will actually consist on terminating the current subscription and creating an all new subscription. Any payments already made for the terminated subscription will be automatically prorated and credited back into the customer's balance.
Each customer can have a completely custom Subscription, but you will usually want people to sign up to a predefined {Plan}. Billingly comes with a {Plan} model and a {SubscriptionsController} which can be extended and enable you to support self-service subscriptions out of the box.

Billingly also lets you offer free trial subscriptions. You can configure a trial termination date when subscribing a customer to any type of plan, billingly will deactivate the customer's account when the date of expiration comes, and will show them a subscription page from where they can signup to any other full plan.

## Installing

### Gem

    gem install billingly

    gem 'billingly'

### Create the tables

### Provide a customer for each request

### Hookup your callbacks

### Configure the routes

### Schedule all the recurring jobs
All the invoicing, deactivating and emailing is done through a rake task (which is idempotent so you shouldn't worry about running it as often as you feel like).

### Customize the templates (optional)

## Common Use Cases
