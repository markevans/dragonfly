require File.dirname(__FILE__) + '/lib/imagetastic'

Imagetastic.url_handler.configure do |c|
  c.protect_from_dos_attacks = false
end

run Imagetastic::App.new
