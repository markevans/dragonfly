generate 'scaffold albums cover_image_uid:string'
rake 'db:migrate'

# 'Vendor' dragonfly in the gems folder
dragonfly_dir = File.expand_path(File.dirname(__FILE__) + '/../../../..')
run "mkdir -p vendor/gems && ln -s #{dragonfly_dir} vendor/gems/dragonfly-0.0.0"

# Set up webrat and cucumber
gem 'cucumber'
generate 'cucumber'

# Copy over all files from the template dir
files_dir = File.expand_path(File.dirname(__FILE__) + '/../files')
run "cp -r #{files_dir}/** ."
