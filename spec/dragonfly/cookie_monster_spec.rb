require 'spec_helper'
require 'rack'

describe Dragonfly::CookieMonster do

  def app(extra_env={})
    Rack::Builder.new do
      use Dragonfly::CookieMonster
      run proc{|env| env.merge!(extra_env); [200, {"Set-Cookie" => "blah", "Something" => "else"}, ["body here"]] }
    end
  end

  it "should not delete the set-cookie header from the response if the response doesn't come from dragonfly" do
    response = Rack::MockRequest.new(app).get('')
    response.status.should == 200
    response.body.should == "body here"
    response.headers["Set-Cookie"].should == "blah"
    response.headers["Something"].should == "else"
  end

  it "should delete the set-cookie header from the response if the response comes from dragonfly" do
    response = Rack::MockRequest.new(app('dragonfly.job' => mock)).get('')
    response.status.should == 200
    response.body.should == "body here"
    response.headers["Set-Cookie"].should be_nil
    response.headers["Something"].should == "else"
  end

end
