require 'fileutils'

RAILS_APP_NAME = 'tmp_app'
FIXTURES_PATH = ROOT_PATH + "/fixtures"

def fixture_path
  "#{FIXTURES_PATH}/rails"
end

def app_path
  "#{fixture_path}/#{RAILS_APP_NAME}"
end

##############################################################################

Given "a Rails application set up for using dragonfly" do
  ok = nil
  FileUtils.cd fixture_path do
    FileUtils.rm_rf RAILS_APP_NAME
    ok = `bundle exec rails new #{RAILS_APP_NAME} -m template.rb`
  end
  raise "Problem setting up Rails app" unless ok
end

Then /^the (.+) cucumber features in my Rails app should pass$/ do |filename|
  puts "\n*** RUNNING FEATURES IN THE RAILS APP... ***\n"
  path = File.join(fixture_path, RAILS_APP_NAME)
  FileUtils.cd path do
    env = ENV['RAILS_ENV']
    ENV['RAILS_ENV'] = 'cucumber'
    `rake db:migrate`
    ENV['RAILS_ENV'] = env
  end
  features_passed = nil
  FileUtils.cd path do
    features_passed = system "cucumber features/#{filename}.feature"
  end
  puts "\n*** FINISHED RUNNING FEATURES IN THE RAILS APP ***\n"
  raise "Features failed" unless features_passed
end
