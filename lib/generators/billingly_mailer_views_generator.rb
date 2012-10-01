require 'rails/generators'

class BillinglyMailerViewsGenerator < Rails::Generators::Base
  self.source_root([File.expand_path("../../../app/views", __FILE__)])

  def create_billingly_mailer_views
    directory 'billingly_mailer', 'app/views/billingly_mailer'
  end
end
