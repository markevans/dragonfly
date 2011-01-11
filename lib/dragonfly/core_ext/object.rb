class Object
  
  # Will eventually get this by cherry-picking from activesupport
  def blank?
    respond_to?(:empty?) ? empty? : !self
  end

  def to_dragonfly_unique_s
    to_s
  end
  
end
