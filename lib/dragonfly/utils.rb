require 'tempfile'

module Dragonfly
  module Utils

    module_function

    def new_tempfile(ext=nil, content=nil)
      tempfile = ext ? Tempfile.new(['dragonfly', ".#{ext}"]) : Tempfile.new('dragonfly')
      tempfile.binmode
      tempfile.write(content) if content
      tempfile.close
      tempfile
    end

  end
end
