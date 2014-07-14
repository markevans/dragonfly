# Tempfile#size reports size of 0 after the tempfile has been
# closed (without unlinking).  This happens because internal
# @tmpfile is set to nil when the Tempfile is closed.
# Alternatively @tmpname is set to nil when file is unlinked.

if RUBY_VERSION < '1.9'
  class Tempfile
    def size
      if @tmpfile
        @tmpfile.flush
        @tmpfile.stat.size
      elsif @tmpname
        File.size(@tmpname)
      else
        0
      end
    end
  end
end
