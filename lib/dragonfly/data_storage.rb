module Dragonfly
  module DataStorage

    # Exceptions
    class DataNotFound < RuntimeError; end
    class UnableToStore < RuntimeError; end
    class DestroyError < RuntimeError; end

  end
end
