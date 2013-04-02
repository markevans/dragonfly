module Dragonfly
  class Content

    # Exceptions
    class NoContent < RuntimeError; end

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
    def_delegators :temp_object, :each

    [:data, :file, :tempfile, :path, :to_file, :size, :each].each do |meth|
      define_method meth do |*args, &block|
        temp_object.send(meth, *args, &block) if temp_object
      end
    end

    def to_file(*args)
      temp_object ? temp_object.to_file(*args) : raise(NoContent, "to_file needs content to be set")
    end

    def name
      meta[:name] || (temp_object.original_filename if temp_object)
    end

    def name=(name)
      meta[:name] = name
    end

    def process!(name, *args)
      processor.process(name, self, *args)
    end

    def analyse(name, *args)
      analyser.analyse(name, self, *args)
    end

    def update(obj, meta=nil)
      self.temp_object = TempObject.new(obj)
      self.meta.merge!(meta) if meta
    end

    private

    attr_writer :temp_object

  end
end
