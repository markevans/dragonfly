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

    attr_reader :temp_object
    attr_accessor :meta
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
      meta["name"] || (temp_object.original_filename if temp_object)
    end

    def name=(name)
      meta["name"] = name
    end

    def process!(name, *args)
      processor.process(name, self, *args)
      self
    end

    def analyse(name, *args)
      analyser.analyse(name, self, *args)
    end

    def update(obj, meta=nil)
      add_meta(meta) if meta
      self.temp_object = TempObject.new(obj, name)
      self
    end

    def add_meta(meta)
      self.meta.merge!(meta)
      self
    end

    private

    attr_writer :temp_object

  end
end
