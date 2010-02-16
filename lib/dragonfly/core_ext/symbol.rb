class Symbol
  
  # Ruby 1.8 reports methods as strings,
  # whereas 1.9 reports them as symbols
  def to_method_name
    RUBY_VERSION =~ /^1.8/ ? to_s : self
  end
  
end
