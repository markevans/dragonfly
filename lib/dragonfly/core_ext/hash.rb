class Hash

  def to_dragonfly_unique_s
    sort_by{|k, v| k.to_dragonfly_unique_s }.to_dragonfly_unique_s
  end

end
