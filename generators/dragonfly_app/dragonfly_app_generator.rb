require 'digest/sha1'

class DragonflyAppGenerator < Rails::Generator::NamedBase
 
  def manifest
    app_name = plural_name
    single_name = singular_name.singularize
    metal_file = "#{single_name}_server"
    metal_name = metal_file.camelize
    path_prefix = 'media'
    
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
        "app/metal/#{metal_file}.rb",
        :assigns => {
          :app_name => app_name,
          :metal_name => metal_name,
          :path_prefix => path_prefix,
          :random_secret => Digest::SHA1.hexdigest(Time.now.to_s)
        }
      )
      
    end
  end

end