run "script/rails generate scaffold albums cover_image_uid:string"
rake 'db:migrate'

# Cucumber generator doesn't seem to be working yet...
# gem 'cucumber'
# run 'script/rails generate cucumber:skeleton'
gem 'rack-cache', :require => 'rack/cache'
run 'echo "" >> Gemfile' # Annoyingly the generators don't insert line-breaks yet
gem 'rmagick', :require => 'RMagick'

# # Copy over all files from the template dir
files_dir = File.expand_path(File.dirname(__FILE__) + '/../../files')
run "cp -r #{files_dir}/** ."
