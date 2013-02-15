source :rubygems

gem "rack"
gem "multi_json", "~> 1.0"

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
  gem 'rspec', '~> 2.5'
  gem 'webmock'
  gem 'yard'
  if RUBY_PLATFORM == "java"
    gem "jruby-openssl"
  else
    gem 'redcarpet', '~>1.0'
    gem 'bluecloth'
    gem 'bson_ext'
  end
end
