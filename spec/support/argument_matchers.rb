def string_matching(regexp)
  Spec::Mocks::ArgumentMatchers::RegexpMatcher.new(regexp)
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

