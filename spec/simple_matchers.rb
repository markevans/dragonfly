def match_url(url)
  simple_matcher("match url #{url}") do |given|
    given_path, given_query_string = given.split('?')
    path, query_string = url.split('?')
    
    path == given_path && given_query_string.split('&').sort == query_string.split('&').sort
  end
end

def be_an_empty_directory
  simple_matcher("be empty") do |given|
    Dir.entries(given) == ['.','..']
  end
end

# The reason we need this is that ActiveRecord 2.x returns just a string/nil, whereas AR 3 always returns an array
def match_ar_error(string)
  simple_matcher("match activerecord error") do |given|
    error = given.is_a?(Array) ? given.first : given
    error == string
  end
end

def include_hash(hash)
  simple_matcher("include hash #{hash}") do |given|
    given.merge(hash) == given
  end
end

def memory_usage
  GC.start # Garbage collect
  `ps -o rss= -p #{$$}`.strip.to_i
end

def leak_memory
  simple_matcher("leak memory") do |given|
    memory_before = memory_usage
    given.call
    memory_after = memory_usage
    result = memory_after > memory_before
    puts "#{memory_after} > #{memory_before}" if result
    result
  end
end
