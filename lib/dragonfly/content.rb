module Dragonfly
  class Content

    include HasFilename
    extend Forwardable

    def initialize(app)
      @app = app
      @meta = {}
    end

    attr_reader :app
    def_delegators :app,
                   :analyser, :processor

    attr_reader :temp_object, :meta

    def name
      meta[:name] || (temp_object.original_filename if temp_object)
    end

    def name=(name)
      meta[:name] = name
    end

    def process!(name, *args)
      processor.process(name, self, *args)
    end

    private

    attr_writer :temp_object

  end
end
