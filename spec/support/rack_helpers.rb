module RackHelpers

  def request(app, path)
    Rack::MockRequest.new(app).get(path)
  end

end
