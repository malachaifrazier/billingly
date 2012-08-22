require 'rails/generators/migration'
require 'rails/generators'

class BillinglyMigrationGenerator < Rails::Generators::Base
  include Rails::Generators::Migration

  def create_billingly_migration
    migration_template 'create_billingly_tables.rb', "db/migrate/create_billingly_tables.rb"
  end

private

  def source_paths
    [File.expand_path("../templates", __FILE__)]
  end

  def self.next_migration_number(path)
    Time.now.utc.strftime("%Y%m%d%H%M%S")
  end
end
