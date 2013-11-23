require 'spec_helper'

describe "configuration" do
  let (:app) { test_app }

  it "adds to fetch_file_whitelist" do
    app.configure do
      fetch_file_whitelist ['something']
    end
    app.fetch_file_whitelist.should include 'something'
  end

  it "adds to fetch_url_whitelist" do
    app.configure do
      fetch_url_whitelist ['http://something']
    end
    app.fetch_url_whitelist.should include 'http://something'
  end
end
