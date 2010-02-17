rails_app_name = 'tmp_app'

def fixture_path(version)
  File.expand_path(File.dirname(__FILE__) + "/../../fixtures/rails_#{version}")
end

Given /^a Rails (.+) application set up for using dragonfly$/ do |version|
  `cd #{fixture_path(version)} &&
    rm -rf #{rails_app_name} &&
    rails -m template.rb #{rails_app_name}`
end

When /^I use the Rails (.+) generator to set up dragonfly$/ do |version|
  `cd #{fixture_path(version)}/#{rails_app_name} &&
    ./script/generate dragonfly_app images`
end

Then /^the cucumber features in my Rails (.+) app should pass$/ do |version|
  puts "\n*** RUNNING FEATURES IN THE RAILS APP... ***\n"
  system "
    cd #{fixture_path(version)}/#{rails_app_name} &&
    RAILS_ENV=cucumber rake db:migrate &&
    cucumber features"
    puts "\n*** FINISHED RUNNING FEATURES IN THE RAILS APP ***\n"
end
