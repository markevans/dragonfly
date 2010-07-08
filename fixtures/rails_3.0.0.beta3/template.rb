gem 'rack-cache', :require => 'rack/cache'
gem 'rmagick', :require => 'RMagick'

gem 'capybara'
gem 'cucumber-rails'
gem 'cucumber', '0.7.2'
gem 'rspec-rails', '2.0.0.beta.8'

generate 'cucumber:skeleton'

generate 'scaffold albums cover_image_uid:string'
rake 'db:migrate'

# Copy over all files from the template dir
files_dir = File.expand_path(File.dirname(__FILE__) + '/../files')
run "cp -r #{files_dir}/** ."
