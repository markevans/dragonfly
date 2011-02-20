source :rubygems

gem "rack"

# These gems are needed for development and testing
group :development, :test, :cucumber do
  gem 'aws-s3'
  gem 'bluecloth'
  gem 'capybara'
  gem 'cucumber', '~>0.10.0'
  gem 'cucumber-rails', '~>0.3.2'
  gem 'database_cleaner'
  gem 'jeweler', '~> 1.5.2'
  gem 'mongo'
  gem 'rack-cache'
  gem 'rails', '3.0.3', :require => nil
  gem 'rake'
  gem 'rspec', '~> 2.5'
  gem 'yard'
  if RUBY_PLATFORM == "java"
    gem "jdbc-sqlite3"
    gem "activerecord-jdbcsqlite3-adapter"
    gem "jruby-openssl"
  else
    gem 'bson_ext'
    gem 'rmagick', '2.12.2', :require => nil
    gem 'sqlite3-ruby'
  end
end
