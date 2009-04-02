module Imagetastic::HelperMethods
  
  def autoload_files_in_dir(namespace, dir)
    Dir.glob("#{dir}/*.rb").each do |file|
      namespace.autoload File.basename(file.sub(/.rb$/,'')).camelize, file
    end
  end
  
  def check_for_required_keys(hash, keys)
    
  end
  
end