class BillinglyMailer < ActionMailer::Base
  def pending_notification(invoice)
    @invoice = invoice
    @cash = invoice.customer.ledger[:cash]
    mail(to: invoice.customer.email, subject: I18n.t('billingly.your_invoice_is_available'))
  end
  
  def overdue_notification(invoice)
    @invoice = invoice
    @cash = invoice.customer.ledger[:cash]
    mail(to: invoice.customer.email, subject: I18n.t('billingly.your_account_was_suspended'))
  end
  
  def paid_notification(invoice)
    @invoice = invoice
    mail(to: invoice.customer.email, subject: I18n.t('billingly.payment_receipt'))
  end
end
