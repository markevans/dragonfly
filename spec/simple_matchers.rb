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