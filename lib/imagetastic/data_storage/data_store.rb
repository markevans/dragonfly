class Imagetastic::DataStorage::DataStore

  def store(image, file) # Receives an ActionController::UploadedTempFile
    raise NotImplementedError
  end

  def retrieve(image) # Receives an Imagetastic::Image model
    raise NotImplementedError
  end

end
