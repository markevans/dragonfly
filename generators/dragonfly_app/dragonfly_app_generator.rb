require 'digest/sha1'

class DragonflyAppGenerator < Rails::Generator::NamedBase
 
  def manifest
    app_name = plural_name
    
    record do |m|
      m.template(
        'initializer.erb',
        File.join('config', 'initializers', "dragonfly_#{app_name}.rb"),
        :assigns => {
          :app_name => app_name,
          :accessor_prefix => singular_name.singularize,
          :path_prefix => 'media',
          :random_secret => Digest::SHA1.hexdigest(Time.now.to_s)
        },
        :collision => :ask
      )
      
    end
  end

end