source :rubygems

gem "rack"

# These gems are needed for development and testing
group :development, :test do
  gem 'activemodel'
  gem 'couchrest', '~> 1.0'
  gem 'fog'
  gem 'github-markup'
  gem 'jeweler'
  gem 'mongo'
  gem 'pry'
  gem 'rack-cache'
  gem 'redcarpet', '~>1.0'
  gem 'rspec', '~> 2.5'
  gem 'webmock'
  gem 'yard'
  if RUBY_PLATFORM == "java"
    gem "jruby-openssl"
  else
    gem 'bluecloth'
    gem 'bson_ext'
  end
end
