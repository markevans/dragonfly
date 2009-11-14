require 'rack/cache'

module Dragonfly
  class MiddlewareWithCache < Middleware
    
    def initialize(app, dragonfly_app_name, rack_cache_opts={})
      super(app, dragonfly_app_name)
      @rack_cache_opts = {
        :verbose     => true,
        :metastore   => 'file:/var/cache/rack/meta',
        :entitystore => 'file:/var/cache/rack/body'
      }.merge(rack_cache_opts)
    end
    
    private
    
    def endpoint
      rack_cache_opts = @rack_cache_opts
      @endpoint ||= Rack::Builder.new do
        use Rack::Cache, rack_cache_opts
        run super
      end
    end
    
  end
end
