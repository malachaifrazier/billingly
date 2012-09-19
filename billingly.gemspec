$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require 'billingly/version'

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = 'billingly'
  s.version     = Billingly::VERSION
  s.authors     = ['Nubis']
  s.email       = ['nubis@woobiz.com.ar']
  s.homepage    = ""
  s.summary     = "Engine for subscriptions billing - still alpha - contact me if you want to use it"
  s.description = "Engine for subscriptions billing - still alpha - contact me if you want to use it"

  s.files = Dir["{app,config,db,lib}/**/*"] + ["MIT-LICENSE", "Rakefile", "README.rdoc"]

  s.add_dependency "rails", "~> 3.2.0"
  s.add_dependency "validates_email_format_of"
  s.add_dependency "has_duration"

  s.add_development_dependency "timecop"
  s.add_development_dependency "sqlite3"
  s.add_development_dependency "rspec-rails"
  s.add_development_dependency "factory_girl_rails"
end
