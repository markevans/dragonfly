generate 'scaffold albums cover_image_uid:string'
rake 'db:migrate'

# 'Vendor' dragonfly in the gems folder
dragonfly_dir = File.expand_path(File.dirname(__FILE__) + '/../../..')
run "mkdir -p vendor/gems && ln -s #{dragonfly_dir} vendor/gems/dragonfly-0.0.0"

# Avoid annoying warnings due to 'vendored' dragonfly gem
run %(ruby -pe '$_ += "\\nRails::VendorGemSourceIndex.silence_spec_warnings = true\\n" if $_ =~ /^require.*boot/' -i.bk config/environment.rb)

# Set up webrat and cucumber
gem 'cucumber'
generate 'cucumber'

# Copy over all files from the template dir
files_dir = File.expand_path(File.dirname(__FILE__) + '/../../files')
run "cp -r #{files_dir}/** ."
