generate 'scaffold albums cover_image_uid:string'
rake 'db:migrate'

# Set up webrat and cucumber
gem 'cucumber'
generate 'cucumber'

gem 'rack-cache', :lib => 'rack/cache'
gem 'rmagick', :lib => 'RMagick'

# Copy over all files from the template dir
files_dir = File.expand_path(File.dirname(__FILE__) + '/../../files')
run "cp -r #{files_dir}/** ."
