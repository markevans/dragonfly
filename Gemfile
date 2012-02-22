source :rubygems

gem "rack"

# These gems are needed for development and testing
group :development, :test, :cucumber do
  gem 'capybara'
  gem 'cucumber', '~>0.10.0'
  gem 'cucumber-rails', '~>0.5.2'
  gem 'database_cleaner'
  gem 'jeweler', '~> 1.5.2'
  gem 'fog'
  gem 'github-markup'
  gem 'mongo'
  gem 'couchrest', '~> 1.0'
  gem 'rack-cache'
  gem 'rails', '~>3.1.0', :require => nil
  gem 'redcarpet', '~>1.0'
  gem 'rspec', '~> 2.5'
  gem 'webmock'
  gem 'yard'
  if RUBY_PLATFORM == "java"
    gem "jdbc-sqlite3"
    gem "activerecord-jdbcsqlite3-adapter"
    gem "jruby-openssl"
  else
    gem 'bluecloth'
    gem 'bson_ext'
    gem 'sqlite3-ruby'
  end
end
