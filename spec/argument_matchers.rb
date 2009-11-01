def string_matching(regexp)
  Spec::Mocks::ArgumentMatchers::RegexpMatcher.new(regexp)
end

class TempObjectArgumentMatcher
  def initialize(data)
    @data = data
  end
  def ==(actual)
    actual.instance_of?(Dragonfly::TempObject) && actual.data == @data
  end
end

def a_temp_object_with_data(data)
  TempObjectArgumentMatcher.new(data)
end
