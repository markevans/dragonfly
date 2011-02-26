require 'pathname'

class String
  
  # Ruby 1.8 reports methods as strings,
  # whereas 1.9 reports them as symbols
  def to_method_name
    RUBY_VERSION =~ /^1.8/ ? self : to_sym
  end

  def to_pathname
    Pathname.new(self)
  end
  
end
