source 'https://rubygems.org'

gemspec

group :development do
  gem 'pry'
  gem 'rake'
end

if defined?(RUBY_ENGINE) && RUBY_ENGINE == 'rbx' && RUBY_VERSION >= '2.0'
  gem "rubysl", "~> 2.0", :group => :development
end
