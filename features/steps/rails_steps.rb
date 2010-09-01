RAILS_APP_NAME = 'tmp_app'
FIXTURES_PATH = ROOT_PATH + "/fixtures"
GEMFILES = {
  '2.3.5' => ROOT_PATH + '/Gemfile.rails.2.3.5',
  '3.0.0' => ROOT_PATH + '/Gemfile',
}

def fixture_path(version)
  "#{FIXTURES_PATH}/rails_#{version}"
end

def app_path(version)
  "#{fixture_path(version)}/#{RAILS_APP_NAME}"
end

##############################################################################

{
  '2.3.5' => "BUNDLE_GEMFILE=#{GEMFILES['2.3.5']} rails #{RAILS_APP_NAME} -m template.rb",
  '3.0.0' => "BUNDLE_GEMFILE=#{GEMFILES['3.0.0']} bundle exec rails new #{RAILS_APP_NAME} -m template.rb"
}.each do |version, rails_command|

  Given /^a Rails #{version} application set up for using dragonfly$/ do
    raise "Problem setting up Rails app" unless `
      cd #{fixture_path(version)} &&
      rm -rf #{RAILS_APP_NAME} &&
      #{rails_command}`
  end
  
end

Then /^the (.+) cucumber features in my Rails (.+) app should pass$/ do |filename, version|
  puts "\n*** RUNNING FEATURES IN THE RAILS APP... ***\n"
  path = File.join(fixture_path(version), RAILS_APP_NAME)
  `cd #{path} && BUNDLE_GEMFILE=#{GEMFILES[version]} RAILS_ENV=cucumber rake db:migrate`
  features_passed = system "cd #{path} && BUNDLE_GEMFILE=#{GEMFILES[version]} cucumber features/#{filename}.feature"
  puts "\n*** FINISHED RUNNING FEATURES IN THE RAILS APP ***\n"
  raise "Features failed" unless features_passed
end
