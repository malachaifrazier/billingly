require 'rails/generators'

class BillinglyViewsGenerator < Rails::Generators::Base
  self.source_root([File.expand_path("../../../app/views", __FILE__)])

  def create_billingly_views
    directory 'billingly', 'app/views'
  end
end
