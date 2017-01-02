require 'sequel'

Sequel.require 'adapters/odbc'
Sequel.require 'adapters/shared/access'

Sequel.synchronize do
  Sequel::ODBC::DATABASE_SETUP[:access] = proc do |db|
    db.extend Sequel::Access::DatabaseMethods
    db.extend_datasets(Sequel::Access::DatasetMethods)
  end
end
