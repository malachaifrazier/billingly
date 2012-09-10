$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require 'billingly/version'

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = 'billingly'
  s.version     = Billingly::VERSION
  s.authors     = ["TODO: Your name"]
  s.email       = ["TODO: Your email"]
  s.homepage    = "TODO"
  s.summary     = "TODO: Summary of RailsSubscriptionBilling."
  s.description = "TODO: Description of RailsSubscriptionBilling."

  s.files = Dir["{app,config,db,lib}/**/*"] + ["MIT-LICENSE", "Rakefile", "README.rdoc"]

  s.add_dependency "rails", "~> 3.2"
  s.add_dependency "validates_email_format_of"

  s.add_development_dependency "timecop"
  s.add_development_dependency "sqlite3"
  s.add_development_dependency "rspec-rails"
  s.add_development_dependency "factory_girl_rails"
end
