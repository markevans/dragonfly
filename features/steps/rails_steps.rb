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
  raise "Problem setting up Rails app" unless `
    cd #{fixture_path} &&
    rm -rf #{RAILS_APP_NAME} &&
    bundle exec rails new #{RAILS_APP_NAME} -m template.rb`
end

Then /^the (.+) cucumber features in my Rails app should pass$/ do |filename|
  puts "\n*** RUNNING FEATURES IN THE RAILS APP... ***\n"
  path = File.join(fixture_path, RAILS_APP_NAME)
  `cd #{path} && RAILS_ENV=cucumber rake db:migrate`
  features_passed = system "cd #{path} && cucumber features/#{filename}.feature"
  puts "\n*** FINISHED RUNNING FEATURES IN THE RAILS APP ***\n"
  raise "Features failed" unless features_passed
end
