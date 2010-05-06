RAILS_APP_NAME = 'tmp_app'
FIXTURES_PATH = File.expand_path(File.dirname(__FILE__) + "/../../fixtures")

def fixture_path(version)
  "#{FIXTURES_PATH}/rails_#{version}"
end

def app_path(version)
  "#{fixture_path(version)}/#{RAILS_APP_NAME}"
end

##############################################################################

Given /^a Rails (.+) application set up for using dragonfly$/ do |version|
  raise "Problem setting up Rails app" unless `
    cd #{fixture_path(version)} &&
    rm -rf #{RAILS_APP_NAME} &&
    rails _#{version}_ #{RAILS_APP_NAME} -m template.rb`
end

When /^I use the provided (.+) initializer$/ do |version|
  FileUtils.cp("#{FIXTURES_PATH}/dragonfly_setup.rb", "#{app_path(version)}/config/initializers")
end

Then /^the cucumber features in my Rails (.+) app should pass$/ do |version|
  puts "\n*** RUNNING FEATURES IN THE RAILS APP... ***\n"
  path = File.join(fixture_path(version), RAILS_APP_NAME)
  `cd #{path} && RAILS_ENV=cucumber rake db:migrate`
  features_passed = system "cd #{path} && cucumber features"
  puts "\n*** FINISHED RUNNING FEATURES IN THE RAILS APP ***\n"
  raise "Features failed" unless features_passed
end
