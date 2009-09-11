class Imagetastic::DataStorage::DataStore

  def store(image)
    raise NotImplementedError
  end

  def retrieve(id)
    raise NotImplementedError
  end

end
