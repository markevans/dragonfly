require 'rack'

module Dragonfly
  class Route
    
    # Exceptions
    class NotFound < RuntimeError; end
    
    include Rack::Utils
  
    def initialize(path_spec)
      @path_spec = path_spec
    end

    def parse_url(path, query_string)
      attrs_from_path  = parse_path(path)
      attrs_from_path.merge(parse_query(query_string))
    end
  
    def to_url(params)
      path = %w(uid job).inject(@path_spec) do |path, meth|
        path.sub(":#{meth}", escape(params.send(meth) || ''))
      end
      # TODO: get remainder as 'query'
      query_string = build_query(query)
      url = path
      url << "?#{build_query(query)}" if query.any?
      url
    end
  
    private
  
    def parse_path(path)
      # TODO
      match_data = Regexp.new(@path_spec).match(path)
      raise NotFound, "path '#{path}' not found" unless match_data
      Hash[[match_data.names, match_data.captures].transpose]
    end
  end
end
