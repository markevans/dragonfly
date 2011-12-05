# AUTOLOAD EVERYTHING IN THE DRAGONFLY DIRECTORY TREE

# The convention is that dirs are modules
# so declare them here and autoload any modules/classes inside them
# All paths here are absolute
camelize = proc do |path|
  # e.g. 'test/this_one' => Test::ThisOne
  "#{path}".
    chomp('/').
    gsub('/','::').
    gsub(/([^a-z])(\w)/){ "#{$1}#{$2.upcase}" }.
    gsub('_','').
    sub(/^(\w)/){ $1.upcase }
end

autoload_files_in_dir = proc do |path, namespace|
  # Define the module
  eval("module #{namespace}; end")
  # Autoload modules/classes in that module
  Dir.glob("#{path}/*.rb").each do |file|
    file = File.expand_path(file)
    sub_const_name = camelize[ File.basename(file, '.rb') ]
    eval("#{namespace}.autoload('#{sub_const_name}', '#{file}')")
  end
  # Recurse on subdirectories
  Dir.glob("#{path}/*/").each do |dir|
    sub_namespace = camelize[ File.basename(dir) ]
    autoload_files_in_dir[dir, "#{namespace}::#{sub_namespace}"]
  end
end

autoload_files_in_dir["#{File.dirname(__FILE__)}/dragonfly", 'Dragonfly']

require 'dragonfly/core_ext/object'
require 'dragonfly/core_ext/array'
require 'dragonfly/core_ext/hash'

Dragonfly::Railtie if defined?(::Rails) # Coz it will autoload

module Dragonfly
  class << self

    def [](*args)
      App[*args]
    end

    # Register saved configurations so we can do e.g.
    # Dragonfly[:my_app].configure_with(:image_magick)
    App.register_configuration(:imagemagick){ ImageMagick::Config }
    App.register_configuration(:image_magick){ ImageMagick::Config }
    App.register_configuration(:rails){ Config::Rails }
    App.register_configuration(:heroku){ Config::Heroku }

    def running_on_windows?
      ENV['OS'] && ENV['OS'].downcase == 'windows_nt'
    end

  end
end
