Spec::Matchers.define :match_url do |url|
  match do |given|
    given_path, given_query_string = given.split('?')
    path, query_string = url.split('?')

    path == given_path && given_query_string.split('&').sort == query_string.split('&').sort
  end
end

Spec::Matchers.define :be_an_empty_directory do
  match do |given|
    Dir.entries(given) == ['.','..']
  end
end

# The reason we need this is that ActiveRecord 2.x returns just a string/nil, whereas AR 3 always returns an array
Spec::Matchers.define :match_ar_error do |string|
  match do |given|
    error = given.is_a?(Array) ? given.first : given
    error == string
  end
end

Spec::Matchers.define :include_hash do |hash|
  match do |given|
    given.merge(hash) == given
  end
end

def memory_usage
  GC.start # Garbage collect
  `ps -o rss= -p #{$$}`.strip.to_i
end

Spec::Matchers.define :leak_memory do
  match do |given|
    memory_before = memory_usage
    given.call
    memory_after = memory_usage
    result = memory_after > memory_before
    puts "#{memory_after} > #{memory_before}" if result
    result
  end
end
