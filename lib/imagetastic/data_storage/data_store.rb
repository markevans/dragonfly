class Imagetastic::DataStorage::DataStore

  def store(data, name)
    raise NotImplementedError
  end

  def retrieve(id)
    raise NotImplementedError
  end

end
