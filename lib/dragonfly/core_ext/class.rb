class Class
  def dragonfly_accessor(attribute, opts={}, &config_block)
    already_extended = respond_to?(:define_dragonfly_instance_methods)
    unless already_extended
      extend Dragonfly::Model
    end
    define_dragonfly_instance_methods(attribute, opts, &config_block)
  end
end
