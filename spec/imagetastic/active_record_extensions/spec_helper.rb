require File.dirname(__FILE__) + '/../../spec_helper'

require 'active_record'

DB_FILE = File.expand_path(File.dirname(__FILE__)+'/db.sqlite3')

%w{migration initializer models}.each do |file|
  require "#{File.dirname(__FILE__)}/#{file}"
end 

Spec::Runner.configure do |config|
  
  config.before(:all) do
    FileUtils.rm_f(DB_FILE)
    ActiveRecord::Base.establish_connection(
       :adapter => "sqlite3",
       :database  => DB_FILE
     )
     MigrationForTest.verbose = false
     MigrationForTest.up
  end
  
end
