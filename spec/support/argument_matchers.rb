def string_matching(regexp)
  Spec::Mocks::ArgumentMatchers::RegexpMatcher.new(regexp)
end

class ArrayIncludingMatcher
  def initialize(expected)
    @expected = expected
  end

  def ==(actual)
    @expected.all? {|v| actual.grep(v).size > 0}
  rescue NoMethodError
    false
  end

  def description
    "array_including(#{@expected.inspect.sub(/^\{/,"").sub(/\}$/,"")})"
  end
end

def array_including(*args)
	actually_an_array = Array === args.first && args.count == 1 ? args.first : args
  ArrayIncludingMatcher.new(actually_an_array)
end

class ContentArgumentMatcher
  def initialize(data)
    @data = data
  end
  def ==(actual)
    actual.is_a?(Dragonfly::Content) &&
      actual.data == @data
  end
end

def content_with_data(data)
  ContentArgumentMatcher.new(data)
end

