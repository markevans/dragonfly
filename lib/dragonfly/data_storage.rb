module Dragonfly
  module DataStorage

    # Exceptions
    class BadUID < RuntimeError; end
    class DataNotFound < RuntimeError; end
    class UnableToStore < RuntimeError; end
    class DestroyError < RuntimeError; end

  end
end
