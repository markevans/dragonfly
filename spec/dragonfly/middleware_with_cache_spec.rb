require File.dirname(__FILE__) + '/shared_middleware_spec'

describe Dragonfly::MiddlewareWithCache do
  
  before(:each) do
    @stack = Rack::Builder.new do
      use Dragonfly::MiddlewareWithCache, :images
      run dummy_rack_app
    end
  end
  
  it_should_behave_like 'dragonfly middleware'
  
end
