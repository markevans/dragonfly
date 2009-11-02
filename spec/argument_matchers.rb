def string_matching(regexp)
  Spec::Mocks::ArgumentMatchers::RegexpMatcher.new(regexp)
end

class TempObjectArgumentMatcher
  def initialize(data)
    @data = data
  end
  def ==(actual)
    actual.is_a?(Dragonfly::TempObject) && actual.data == @data
  end
end

def a_temp_object_with_data(data)
  TempObjectArgumentMatcher.new(data)
end

class ParametersArgumentMatcher
  def initialize(hash)
    @hash = hash
  end
  def ==(actual)
    actual.to_hash.reject{|k,v| v.nil? || v.respond_to?(:empty?) && v.empty?} == @hash
  end
end

def parameters_matching(hash)
  ParametersArgumentMatcher.new(hash)
end
