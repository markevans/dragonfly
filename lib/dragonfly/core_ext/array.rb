class Array

  def to_dragonfly_unique_s
    map{|item| item.to_dragonfly_unique_s }.join
  end

end
