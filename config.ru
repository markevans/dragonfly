require File.dirname(__FILE__) + '/lib/imagetastic'

app = Imagetastic::App.new

app.url_handler.configure do |c|
  # c.protect_from_dos_attacks = false
end

run app
