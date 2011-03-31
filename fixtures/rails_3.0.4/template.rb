gem 'rack-cache', :require => 'rack/cache'

gem 'capybara'
gem 'cucumber-rails'
gem 'cucumber', '0.8.5'

generate 'cucumber:install'

generate 'scaffold albums cover_image_uid:string name:string'
rake 'db:migrate'

# Copy over all files from the template dir
files_dir = File.expand_path(File.dirname(__FILE__) + '/files')
run "cp -r #{files_dir}/** ."

route <<ROUTES
  match '/text/:text/:size' => Dragonfly[:images].endpoint{|params, app|
    app.generate(:text, params[:text]).thumb(params[:size])
  }
ROUTES
