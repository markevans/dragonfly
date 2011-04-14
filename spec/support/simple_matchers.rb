RSpec::Matchers.define :match_url do |url|
  match do |given|
    given_path, given_query_string = given.split('?')
    path, query_string = url.split('?')

    path == given_path && given_query_string.split('&').sort == query_string.split('&').sort
  end
end

RSpec::Matchers.define :be_an_empty_directory do
  match do |given|
    Dir.entries(given) == ['.','..']
  end
end

RSpec::Matchers.define :include_hash do |hash|
  match do |given|
    given.merge(hash) == given
  end
end

def memory_usage
  GC.start # Garbage collect
  `ps -o rss= -p #{$$}`.strip.to_i
end

RSpec::Matchers.define :leak_memory do
  match do |given|
    memory_before = memory_usage
    given.call
    memory_after = memory_usage
    result = memory_after > memory_before
    puts "#{memory_after} > #{memory_before}" if result
    result
  end
end

RSpec::Matchers.define :match_attachment_classes do |classes|
  match do |given_classes|
    given_classes.length == classes.length &&
      classes.zip(given_classes).all? do |(klass, given)|
        given.model_class == klass[0] && given.attribute == klass[1] && given.app == klass[2]
      end
  end
end

RSpec::Matchers.define :be_a_text_response do
  match do |given_response|
    given_response.status.should == 200
    given_response.body.length.should > 0
    given_response.content_type.should == 'text/plain'
  end
end
