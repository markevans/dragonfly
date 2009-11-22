module Dragonfly
  module StandardConfiguration
    
    def self.apply_configuration(app)
      app.configure do |c|
        c.datastore = DataStorage::FileDataStore.new
        c.register_analyser(Analysis::FileCommandAnalyser)
        c.register_encoder(Encoding::TransparentEncoder)
      end
    end
    
  end  
end
