class ImagetasticAppGenerator < Rails::Generator::NamedBase
 
  def initialize(*args)
    super
    raise "The args are #{args}.inspect"
  end
 
  def manifest    
    record do |m|
      m.migration_template("metal_file.rb", File.join('app', 'metal'))
    end
  end 

end