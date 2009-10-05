require File.dirname(__FILE__) + '/lib/imagetastic'

app = Imagetastic::App.new
app.datastore = Imagetastic::DataStorage::FileDataStore.new
app.processor.register(Imagetastic::Processing::RMagickProcessor)
app.encoder = Imagetastic::Encoding::RMagickEncoder.new

app.url_handler.configure do |c|
  c.protect_from_dos_attacks = false
end

run app
