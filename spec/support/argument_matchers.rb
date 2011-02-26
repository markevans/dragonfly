def string_matching(regexp)
  Spec::Mocks::ArgumentMatchers::RegexpMatcher.new(regexp)
end

class TempObjectArgumentMatcher
  def initialize(data, opts)
    @data = data
    @opts = opts
  end
  def ==(actual)
    actual.is_a?(Dragonfly::TempObject) &&
      actual.data == @data &&
      @opts.all?{|k,v| actual.send(k) == v }
  end
end

def a_temp_object_with_data(data, opts={})
  TempObjectArgumentMatcher.new(data, opts)
end
