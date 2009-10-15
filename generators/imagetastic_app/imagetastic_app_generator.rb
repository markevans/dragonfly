require 'digest/sha1'

class ImagetasticAppGenerator < Rails::Generator::NamedBase
 
  def manifest
    app_name = plural_name
    metal_name = plural_name.camelize
    path_prefix = plural_name
    single_name = singular_name.singularize
    
    record do |m|
      # The initializer
      initializer_path = File.join(Rails.root, 'config', 'initializers', 'imagetastic.rb')
      already_initialized_code = File.read(initializer_path) if File.exists?(initializer_path)
      m.template(
        'initializer.erb',
        'config/initializers/imagetastic.rb',
        :assigns => {
          :app_name => app_name,
          :accessor_prefix => single_name,
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
          :random_secret => Digest::SHA1.hexdigest(Time.now.to_s)
        }
      )
      
      # The custom processor
      m.template(
        'custom_processing.erb',
        "lib/custom_#{singular_name}_processing.rb",
        :assigns => {
          :module_name => "Custom#{singular_name.camelize}Processing",
          :temp_object_name => single_name
        }
      )
      
    end
  end

end