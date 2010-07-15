RAILS_APP_NAME = 'tmp_app'
FIXTURES_PATH = File.expand_path(File.dirname(__FILE__) + "/../../fixtures")

def fixture_path(version)
  "#{FIXTURES_PATH}/rails_#{version}"
end

def app_path(version)
  "#{fixture_path(version)}/#{RAILS_APP_NAME}"
end

##############################################################################

{
  '2.3.5' => "rails _2.3.5_ #{RAILS_APP_NAME} -m template.rb",
  '3.0.0.beta4' => "rails _3.0.0.beta4_ new #{RAILS_APP_NAME} -m template.rb"
}.each do |version, rails_command|

  Given /^a Rails #{version} application set up for using dragonfly$/ do
    raise "Problem setting up Rails app" unless `
      cd #{fixture_path(version)} &&
      rm -rf #{RAILS_APP_NAME} &&
      #{rails_command}`
  end
  
end

Then /^the cucumber features in my Rails (.+) app should pass$/ do |version|
  puts "\n*** RUNNING FEATURES IN THE RAILS APP... ***\n"
  path = File.join(fixture_path(version), RAILS_APP_NAME)
  `cd #{path} && RAILS_ENV=cucumber rake db:migrate`
  features_passed = system "cd #{path} && cucumber features"
  puts "\n*** FINISHED RUNNING FEATURES IN THE RAILS APP ***\n"
  raise "Features failed" unless features_passed
end
