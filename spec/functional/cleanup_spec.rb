require 'spec_helper'

describe "cleaning up tempfiles" do

  let (:app) {
    test_app.configure{
      processor :copy do |content|
        content.shell_update do |old_path, new_path|
          "cp #{old_path} #{new_path}"
        end
      end
    }
  }

  it "unlinks tempfiles on each request" do
    expect {
      uid = app.store("blug")
      url = app.fetch(uid).copy.url
      request(app, url)
    }.not_to increase_num_tempfiles
  end
end
