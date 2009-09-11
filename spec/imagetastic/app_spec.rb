require File.dirname(__FILE__) + '/../spec_helper'
require 'rack/mock'

describe Imagetastic::App do

  before(:each) do
    @app = Imagetastic::App.new
    @request = Rack::MockRequest.new(@app)
  end

end