# AUTOLOAD EVERYTHING IN THE IMAGETASTIC DIRECTORY TREE

# The convention is that dirs are modules
# so declare them here and autoload any modules/classes inside them
# All paths here are absolute
def camelize(path)
  # e.g. 'test/this_one' => Test::ThisOne
  "#{path}".
    chomp('/').
    gsub('/','::').
    gsub(/([^a-z])(\w)/){ "#{$1}#{$2.upcase}" }.
    gsub('_','').
    sub(/^(\w)/){ $1.upcase }
end
def autoload_files_in_dir(path, namespace)
  # Define the module
  eval ("module #{namespace}; end")
  # Autoload modules/classes in that module
  Dir.glob("#{path}/*.rb").each do |file|
    sub_const_name = camelize( File.basename(file, '.rb') )
    eval("#{namespace}.autoload('#{sub_const_name}', '#{file}')")
  end
  # Recurse on subdirectories
  Dir.glob("#{path}/*/").each do |dir|
    sub_namespace = camelize( File.basename(dir) )
    autoload_files_in_dir(dir, "#{namespace}::#{sub_namespace}")
  end
end

autoload_files_in_dir("#{File.dirname(__FILE__)}/imagetastic", 'Imagetastic')

# Config
module Imagetastic
  class << self
    include Configurable
    configurable_attr :datastore,        DataStorage::FileDataStore.new
    configurable_attr :format_converter, ImageProcessing::ImageMagick::FormatConverter.new
    configurable_attr :image_processor,  ImageProcessing::ImageMagick::ImageProcessor.new
    configurable_attr :image_analyser,   ImageProcessing::ImageMagick::ImageAnalyser.new
  end
end