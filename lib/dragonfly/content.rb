module Dragonfly
  class Content

    # Exceptions
    class NoContent < RuntimeError; end

    include HasFilename
    extend Forwardable

    def initialize(app, obj=nil, meta=nil)
      @app = app
      @meta = {}
      @previous_temp_objects = []
      update(obj, meta) if obj
    end

    def initialize_copy(other)
      @unique_id = nil
    end

    attr_reader :app
    def_delegators :app,
                   :analyser, :processor, :shell

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

    def shell_eval(opts={})
      should_escape = opts[:escape] != false
      command = yield(should_escape ? shell.quote(path) : path)
      shell.run command, :escape => should_escape
    end

    def shell_update(opts={})
      ext = opts[:ext] || self.ext
      should_escape = opts[:escape] != false
      tempfile = Dragonfly::Utils.new_tempfile(ext)
      old_path = should_escape ? shell.quote(path) : path
      new_path = should_escape ? shell.quote(tempfile.path) : tempfile.path
      command = yield(old_path, new_path)
      shell.run(command, :escape => should_escape)
      update(tempfile)
    end

    def close
      previous_temp_objects.each{|temp_object| temp_object.close }
      temp_object.close if temp_object
    end

    def unique_id
      @unique_id ||= "#{object_id}#{rand(1000000)}"
    end

    private

    attr_reader :previous_temp_objects
    def temp_object=(temp_object)
      previous_temp_objects.push(@temp_object) if @temp_object
      @temp_object = temp_object
    end

  end
end
