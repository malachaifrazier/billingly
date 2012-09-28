module Billingly
  def self.table_name_prefix
    'billingly_'
  end

  class Engine < Rails::Engine
    def self.app_path
      File.expand_path('../../app', called_from)
    end

    %w{controller helper mailer model}.each do |resource|
      class_eval <<-RUBY
        def self.#{resource}_path(name)
          File.expand_path("#{resource.pluralize}/billingly/\#{name}.rb", app_path)
        end
      RUBY
    end
  
    # Extends the ApplicationController with all the
    # billingly before_filters and helper methods
    initializer 'billingly.app_controller' do |app|
      ActiveSupport.on_load(:action_controller) do
        class_eval do
          def current_customer
            nil
          end

          def requires_customer
            on_empty_customer if current_customer.nil? 
          end

          # This method is call on a before filter when a customer was required
          # but none was found. It's reccommended that this method redirects to
          # a login url or out of the site.
          def on_empty_customer
            redirect_to(root_path)
          end
          
          # This before filter should apply to all actions that require an active
          # customer. Usually this would mean all your non-public pages.
          # The billingly controllers already apply this before filter, you should
          # use it in your own controllers too.
          def requires_active_customer
            if requires_customer.nil? && current_customer.deactivated?
              redirect_to(subscriptions_path)
            end
          end
        end

        helper_method :current_customer
      end
    end
  end
end

