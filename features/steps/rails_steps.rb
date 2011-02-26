RAILS_APP_NAME = 'tmp_app'
FIXTURES_PATH = ROOT_PATH + "/fixtures"

def fixture_path(version)
  "#{FIXTURES_PATH}/rails_#{version}"
end

def app_path(version)
  "#{fixture_path(version)}/#{RAILS_APP_NAME}"
end

##############################################################################

Given "a Rails 3.0.4 application set up for using dragonfly" do
  raise "Problem setting up Rails app" unless `
    cd #{fixture_path('3.0.4')} &&
    rm -rf #{RAILS_APP_NAME} &&
    bundle exec rails new #{RAILS_APP_NAME} -m template.rb`
end

Then /^the (.+) cucumber features in my Rails (.+) app should pass$/ do |filename, version|
  puts "\n*** RUNNING FEATURES IN THE RAILS APP... ***\n"
  path = File.join(fixture_path(version), RAILS_APP_NAME)
  `cd #{path} && RAILS_ENV=cucumber rake db:migrate`
  features_passed = system "cd #{path} && cucumber features/#{filename}.feature"
  puts "\n*** FINISHED RUNNING FEATURES IN THE RAILS APP ***\n"
  raise "Features failed" unless features_passed
end
