class Imagetastic::Processing::Processor

  def process(data, method, options)
    send(method, data, options)
  end

end
