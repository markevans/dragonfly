rails_app_name = 'tmp_app'

def fixture_path(version)
  File.expand_path(File.dirname(__FILE__) + "/../../fixtures/rails_#{version}")
end

def insert_line(line, after_expr, file)
  `ruby -pe '$_ += "\\n#{line}\\n" if $_ =~ /#{after_expr}/' -i.bk #{file}`
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

When /^I use config\.gem to require the Rails (.+) initializer$/ do |version|
  env_file = "#{fixture_path(version)}/#{rails_app_name}/config/environment.rb"
  line = "config.gem \\\"dragonfly\\\", :lib => \\\"dragonfly/rails/images\\\""
  `ruby -pe '$_ += "\\n#{line}\\n" if $_ =~ /^Rails::Initializer\.run/' -i.bk #{env_file}`
end

Then /^the cucumber features in my Rails (.+) app should pass$/ do |version|
  puts "\n*** RUNNING FEATURES IN THE RAILS APP... ***\n"
  features_passed = system "
    cd #{fixture_path(version)}/#{rails_app_name} &&
    RAILS_ENV=cucumber rake db:migrate &&
    cucumber features"
  puts "\n*** FINISHED RUNNING FEATURES IN THE RAILS APP ***\n"
  raise "Features failed" unless features_passed
end
