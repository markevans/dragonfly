# AUTOLOAD EVERYTHING IN THE IMAGETASTIC DIRECTORY TREE

# The convention is that dirs are modules
# so declare them here and autoload any modules/classes inside them
# path is relative to this file
def path_to_constant(path)
  # e.g. 'test/this_one' => Test::ThisOne
  "#{path}".
    chomp('/').
    gsub('/','::').
    gsub(/([^a-z])(\w)/){ "#{$1}#{$2.upcase}" }.
    gsub('_','').
    sub(/^(\w)/){ $1.upcase }
end
def autoload_files_in_dir(path)
  constant_name = '::' + path_to_constant(path)
  # Define the module
  eval "module #{constant_name}; end"
  # Autoload modules/classes in that module
  Dir.glob("#{path}/*.rb").each do |file|
    sub_const_name = path_to_constant( File.basename(file).sub('.rb','') )
    filename = File.expand_path(file)
    puts "#{constant_name}.autoload('#{sub_const_name}', '#{filename}')"
  end
  Dir.glob("#{path}/*/").each do |dir|
    autoload_files_in_dir(dir)
  end
end

autoload_files_in_dir('imagetastic')

# # Extends
# ActiveRecord::Base.extend Imagetastic::Model::Macro
# ActionController::Base.extend Imagetastic::Controller::Macro

# Config
# Imagetastic.configure do |config|    
#   config.datastore        = Imagetastic::DataStorage::FileDataStore.new
#   config.format_converter = Imagetastic::ImageProcessing::ImageMagick::FormatConverter.new
#   config.image_processor  = Imagetastic::ImageProcessing::ImageMagick::ImageProcessor.new
#   config.image_analyser   = Imagetastic::ImageProcessing::ImageMagick::ImageAnalyser.new
# end