# Billingly

![Travis Build Status](https://secure.travis-ci.org/nubis/billingly.png)

Billingly is a rails 3 engine that manages paid subscriptions and free trials to your web application. 

Billingly can:

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

Billingly does not receive payments directly (from Paypal, or Worldpay for example). However, you can use [ActiveMerchant](http://activemerchant.org) for handling payment notifications from third party services, and easily hookup Billingly to credit the payment into your customer's account. Billingly will take care of all the rest.

# Getting Started
  * Read the [Getting Started Guide](http://rubydoc.info/github/nubis/billingly/master/file/TUTORIAL.rdoc).
  * Check out the [Demo App](http://billing.ly).
  * Explore the [Docs](http://rubydoc.info/github/nubis/billingly/master/frames/file/README.md).

# License
  MIT License. Copyright 2012 Nubis (nubis@woobiz.com.ar)

