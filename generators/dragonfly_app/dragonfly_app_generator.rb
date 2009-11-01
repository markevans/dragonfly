require 'digest/sha1'

class DragonflyAppGenerator < Rails::Generator::NamedBase
 
  def manifest
    app_name = plural_name
    metal_name = plural_name.camelize
    path_prefix = plural_name
    single_name = singular_name.singularize
    custom_processor_name = "Custom#{single_name.camelize}Processing"
    
    record do |m|
      # The initializer
      initializer_path = File.join(Rails.root, 'config', 'initializers', 'dragonfly.rb')
      already_initialized_code = File.read(initializer_path) if File.exists?(initializer_path)
      m.template(
        'initializer.erb',
        'config/initializers/dragonfly.rb',
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
          :random_secret => Digest::SHA1.hexdigest(Time.now.to_s),
          :custom_processor_name => custom_processor_name
        }
      )
      
      # The custom processor
      m.template(
        'custom_processing.erb',
        "lib/#{custom_processor_name.underscore}.rb",
        :assigns => {
          :module_name => custom_processor_name,
          :temp_object_name => single_name
        }
      )
      
    end
  end

end