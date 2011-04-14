class Object
  
  # Don't want to depend on activesupport for this
  def blank?
    respond_to?(:empty?) ? empty? : !self
  end

  def to_dragonfly_unique_s
    to_s
  end
  
end
