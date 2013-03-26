source :rubygems

# These gems are needed for development and testing
group :development, :test, :cucumber do
  gem 'aws-s3'
  gem 'capybara'
  gem 'cucumber'
  gem 'cucumber-rails'
  gem 'database_cleaner', '>= 0.5.0'
  gem 'jeweler',  '~> 1.4'
  gem 'gherkin', '~> 2.11.6'
  gem 'mongo'
  gem 'nokogiri', '1.5.0.beta.2' # 1.4.3.1 segfaults on Ruby 1.9.2
  gem 'rack', '~>1.1'
  gem 'rack-cache'
  gem 'rails', '3.0.3', :require => nil
  gem 'rake', '= 0.8.7'
  gem 'rspec', '~> 1.3'
  gem 'yard'
  if RUBY_PLATFORM == "java"
    gem "jdbc-sqlite3"
    gem "activerecord-jdbcsqlite3-adapter"
    gem "jruby-openssl"
  else
    gem 'bson_ext'
    gem 'rmagick', '2.12.2', :require => nil
    gem 'sqlite3-ruby', '1.3.0' # 1.3.1 segfaults on Ruby 1.9.2
  end
end
