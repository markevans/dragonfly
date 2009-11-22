module Dragonfly
  module StandardConfiguration
    
    def self.apply_configuration(app)
      app.configure do |c|
        c.datastore = DataStorage::FileDataStore.new
        c.encoder = Encoding::TransparentEncoder.new
        c.analyser do |a|
          a.register(Analysis::FileCommandAnalyser)
        end
      end
    end
    
  end  
end
