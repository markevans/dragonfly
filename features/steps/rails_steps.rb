RAILS_APP_NAME = 'tmp_app'

def fixture_path(version)
  File.expand_path(File.dirname(__FILE__) + "/../../fixtures/rails_#{version}")
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

When /^I use the Rails (.+) generator to set up dragonfly$/ do |version|
  raise "Problem using the generator" unless `
    cd #{fixture_path(version)}/#{RAILS_APP_NAME} &&
    ./script/generate dragonfly_app images`
end

When /^I use config\.gem to require the Rails (.+) initializer$/ do |version|
  env_file = "#{fixture_path(version)}/#{RAILS_APP_NAME}/config/environment.rb"
  line = "config.gem \\\"dragonfly\\\", :lib => \\\"dragonfly/rails/images\\\""
  raise "Problem inserting config.gem line" unless `
    ruby -pe '$_ += "\\n#{line}\\n" if $_ =~ /^Rails::Initializer\.run/' -i.bk #{env_file}`
end

When /^I use the provided (.+) initializer$/ do |version|
  `echo "
    gem 'rack-cache', :require => 'rack/cache'
    gem 'rmagick', :require => 'RMagick'
    " >> #{app_path(version)}/Gemfile`
  FileUtils.cp("#{fixture_path(version)}/initializer.rb", "#{app_path(version)}/config/initializers/dragonfly.rb")
end

Then /^the cucumber features in my Rails (.+) app should pass$/ do |version|
  puts "\n*** RUNNING FEATURES IN THE RAILS APP... ***\n"
  features_passed = system "
    cd #{fixture_path(version)}/#{RAILS_APP_NAME} &&
    RAILS_ENV=cucumber rake db:migrate &&
    cucumber features"
  puts "\n*** FINISHED RUNNING FEATURES IN THE RAILS APP ***\n"
  raise "Features failed" unless features_passed
end
