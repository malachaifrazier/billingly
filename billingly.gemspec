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
end
