class DragonflyGenerator < Rails::Generators::Base
  source_root File.expand_path('../templates', __FILE__)
  
  def create_initializer
    template "initializer.rb", "config/initializers/dragonfly.rb"
  end
end
