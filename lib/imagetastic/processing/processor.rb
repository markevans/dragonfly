class Imagetastic::Processing::Processor

  def process(image, method, options)
    send(method, image, options)
  end

end
