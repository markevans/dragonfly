class ImagetasticAppGenerator < Rails::Generator::NamedBase
 
  def manifest
    app_name = plural_name
    metal_name = plural_name.camelize
    path_prefix = plural_name
    accessor_prefix = singular_name.singularize
    
    record do |m|
      # The initializer
      initializer_path = File.join(Rails.root, 'config', 'initializers', 'imagetastic.rb')
      already_initialized_code = File.read(initializer_path) if File.exists?(initializer_path)
      m.template(
        'initializer.erb',
        'config/initializers/imagetastic.rb',
        :assigns => {
          :app_name => app_name,
          :accessor_prefix => accessor_prefix,
          :already_initialized_code => already_initialized_code
        },
        :collision => :force
      )
      
      # The metal file
      m.directory('app/metal')
      m.template(
        'metal_file.erb',
        "app/metal/#{plural_name}.rb",
        :assigns => {
          :app_name => app_name,
          :metal_name => metal_name,
          :path_prefix => path_prefix,
        }
      )
    end
  end

end