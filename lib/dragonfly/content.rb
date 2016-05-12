require 'base64'
require 'forwardable'
require 'dragonfly/has_filename'
require 'dragonfly/temp_object'
require 'dragonfly/utils'

module Dragonfly

  # A Dragonfly::Content object is responsible for holding
  # 1. content (in the form of a data string, file, tempfile, or path)
  # 2. metadata about the content (i.e. name, etc.)
  # Furthermore, it belongs to a Dragonfly app, so has access to its already registered generators, processors, analysers and datastore.
  # It provides convenience methods for updating its content, and though the original data may have been in the form of a String, or a Pathname, etc.
  # methods like "path", "data" and "file" will always work regardless.
  #
  # It is acted upon in generator, processor, analyser and datastore methods and provides a standard interface for updating content,
  # no matter how that content first got there (whether in the form of a String/Pathname/File/etc.)
  class Content

    include HasFilename
    extend Forwardable

    def initialize(app, obj="", meta=nil)
      @app = app
      @meta = {}
      @previous_temp_objects = []
      update(obj, meta)
    end

    # Used by 'dup' and 'clone'
    def initialize_copy(other)
      self.meta = meta.dup
    end

    attr_reader :app
    def_delegators :app,
                   :analyser, :generator, :processor, :shell, :datastore, :env

    attr_reader :temp_object

    # @return [Hash]
    attr_accessor :meta

    # @!method data
    #   @return [String] the content data as a string (even if it was initialized with a file)
    # @!method file
    #   @example
    #     content.file
    #   @example With a block (it closes the file at the end)
    #     content.file do |f|
    #       # do something with f
    #     end
    #   @return [File] the content as a readable file (even if it was initialized with data)
    # @!method path
    #   @return [String] a file path for the content (even if it was initialized with data)
    # @!method size
    #   @return [Fixnum] the size in bytes
    # @!method to_file
    #   @param [String] path
    #   @return [File] a new file
    # @!method to_tempfile
    #   @return [Tempfile] a new tempfile
    def_delegators :temp_object,
                   :data, :file, :tempfile, :path, :size, :each, :to_file, :to_tempfile

    # @example "beach.jpg"
    # @return [String]
    def name
      meta["name"]
    end

    # @example
    #   content.name = "beach.jpg"
    def name=(name)
      meta["name"] = name
    end

    # The mime-type taken from the name's file extension
    # @example "image/jpeg"
    # @return [String]
    def mime_type
      meta['mime_type'] || app.mime_type_for(ext)
    end

    # Set the content using a pre-registered generator
    # @example
    #   content.generate!(:text, "some text")
    # @return [Content] self
    def generate!(name, *args)
      app.get_generator(name).call(self, *args)
      self
    end

    # Update the content using a pre-registered processor
    # @example
    #   content.process!(:convert, "-resize 300x300")
    # @return [Content] self
    def process!(name, *args)
      app.get_processor(name).call(self, *args)
      self
    end

    # Analyse the content using a pre-registered analyser
    # @example
    #   content.analyse(:width)  # ===> 280
    def analyse(name)
      analyser_cache[name.to_s] ||= app.get_analyser(name).call(self)
    end

    # Update the content
    # @param obj [String, Pathname, Tempfile, File, Content, TempObject] can be any of these types
    # @param meta [Hash] - should be json-like, i.e. contain no types other than String, Number, Boolean
    # @return [Content] self
    def update(obj, meta=nil)
      meta ||= {}
      self.temp_object = TempObject.new(obj, meta['name'])
      self.meta['name'] ||= temp_object.name if temp_object.name
      clear_analyser_cache
      add_meta(obj.meta) if obj.respond_to?(:meta)
      add_meta(meta)
      self
    end

    # Add to the meta (merge)
    # @param meta [Hash] - should be json-like, i.e. contain no types other than String, Number, Boolean
    def add_meta(meta)
      self.meta.merge!(meta)
      self
    end

    # Analyse the content using a shell command
    # @param opts [Hash] passing :escape => false doesn't shell-escape each word
    # @example
    #   content.shell_eval do |path|
    #     "file --mime-type #{path}"
    #   end
    #   # ===> "beach.jpg: image/jpeg"
    def shell_eval(opts={})
      should_escape = opts[:escape] != false
      command = yield(should_escape ? shell.quote(path) : path)
      run command, :escape => should_escape
    end

    # Set the content using a shell command
    # @param opts [Hash] :ext sets the file extension of the new path and :escape => false doesn't shell-escape each word
    # @example
    #   content.shell_generate do |path|
    #     "/usr/local/bin/generate_text gumfry -o #{path}"
    #   end
    # @return [Content] self
    def shell_generate(opts={})
      ext = opts[:ext] || self.ext
      should_escape = opts[:escape] != false
      tempfile = Utils.new_tempfile(ext)
      new_path = should_escape ? shell.quote(tempfile.path) : tempfile.path
      command = yield(new_path)
      run(command, :escape => should_escape)
      update(tempfile)
    end

    # Update the content using a shell command
    # @param opts [Hash] :ext sets the file extension of the new path and :escape => false doesn't shell-escape each word
    # @example
    #   content.shell_update do |old_path, new_path|
    #     "convert -resize 20x10 #{old_path} #{new_path}"
    #   end
    # @return [Content] self
    def shell_update(opts={})
      ext = opts[:ext] || self.ext
      should_escape = opts[:escape] != false
      tempfile = Utils.new_tempfile(ext)
      old_path = should_escape ? shell.quote(path) : path
      new_path = should_escape ? shell.quote(tempfile.path) : tempfile.path
      command = yield(old_path, new_path)
      run(command, :escape => should_escape)
      update(tempfile)
    end

    def store(opts={})
      datastore.write(self, opts)
    end

    # @example
    #   "data:image/jpeg;base64,IGSsdhfsoi..."
    # @return [String] A data url representation of the data
    def b64_data
      "data:#{mime_type};base64,#{Base64.encode64(data)}"
    end

    def close
      previous_temp_objects.each{|temp_object| temp_object.close }
      temp_object.close
    end

    def inspect
      "<#{self.class.name} temp_object=#{temp_object.inspect}>"
    end

    private

    attr_reader :previous_temp_objects
    def temp_object=(temp_object)
      previous_temp_objects.push(@temp_object) if @temp_object
      @temp_object = temp_object
    end

    def analyser_cache
      @analyser_cache ||= {}
    end

    def clear_analyser_cache
      analyser_cache.clear
    end

    def run(command, opts)
      shell.run(command, opts)
    end

  end
end
