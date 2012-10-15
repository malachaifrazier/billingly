$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require 'billingly/version'

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = 'billingly'
  s.version     = Billingly::VERSION
  s.authors     = ['Nubis']
  s.email       = ['nubis@woobiz.com.ar']
  s.homepage    = "http://billing.ly"
  s.summary     = "Rails Engine for SaaS subscription management"
  s.description = "Rails Engine for SaaS subscription management. Manage subscriptions, plan changes, free trials and more!!!"

  s.files = Dir["{app,config,db,lib}/**/*"] + ["MIT-LICENSE", "Rakefile", "README.md", "TUTORIAL.rdoc"]

  s.add_dependency "rails", "~> 3.2.0"
  s.add_dependency "validates_email_format_of"
  s.add_dependency "has_duration"

  s.add_development_dependency "timecop"
  s.add_development_dependency "sqlite3"
  s.add_development_dependency "rspec-rails"
  s.add_development_dependency "factory_girl_rails"

  s.post_install_message = <<-END
    Add the following migration:
    
    class CreateBillinglyTables < ActiveRecord::Migration
      def up
        add_column :billingly_subscriptions, :notified_trial_will_expire_on, :datetime
        add_column :billingly_subscriptions, :notified_trial_expired_on, :datetime
        add_column :billingly_subscriptions, :unsubscribed_because, :string
        
        Billingly::Subscription.where('unsubscribed_on IS NOT NULL').find_each do |s|
          # Notice: You should pre-populate unsubscribed because
          # with an appropriate value for each terminated subscription.
          # 
          reason = if s == s.customer.subscriptions.last && s.customer.deactivation_reason
            s.deactivation_reason
          elsif s.trial? && s.is_trial_expiring_on <= s.unsubscribed_on
            'trial_expired'
          else
            'changed_subscription'
          end
          s.update_attribute(unsubscribed_because: reason)
        end
      end
      
      def down
        remove_column :billingly_subscriptions, :notified_trial_will_expire_on
        remove_column :billingly_subscriptions, :notified_trial_expired_on
        remove_column :billingly_subscriptions, :unsubscribed_because
      end
    end
  END
end
