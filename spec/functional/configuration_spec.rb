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

  describe "deprecations" do
    it "protect_from_dos_attacks" do
      Dragonfly.should_receive(:warn).with(/deprecated/)
      expect {
        app.configure do
          protect_from_dos_attacks false
        end
      }.to change(app.server, :verify_urls)
    end
  end

end
