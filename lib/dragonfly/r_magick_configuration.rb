module Dragonfly
  
  RMagickConfiguration = AppConfiguration.new
  
  def RMagickConfiguration.apply_configuration(app)
    app.configure do |c|
      c.datastore = DataStorage::FileDataStore.new
      c.analyser do |a|
        a.register(Analysis::RMagickAnalyser.new)
      end
      c.processor do |p|
        p.register(Processing::RMagickProcessor)
      end
      c.encoder = Encoding::RMagickEncoder.new
      c.parameters do |p|
        p.default_format = :jpg
        # Standard resizing like '30x40!', etc.
        p.add_shortcut(/^\d*x\d*[><%^!]?$|^\d+@$/) do |geometry, match_data|
          {
            :processing_method => :resize,
            :processing_options => {:geometry => geometry}
          }
        end
        # Cropped resizing like '20x50#ne'
        p.add_shortcut(/^(\d+)x(\d+)#(\w{1,2})?/) do |geometry, match_data|
          {
            :processing_method => :resize_and_crop,
            :processing_options => {:width => match_data[1], :height => match_data[2], :gravity => match_data[3]}
          }
        end
        # Cropping like '30x30+10+10ne'
        p.add_shortcut(/^(\d+)x(\d+)([+-]\d+)([+-]\d+)(\w{1,2})?/) do |geometry, match_data|
          {
            :processing_method => :crop,
            :processing_options => {
              :width => match_data[1],
              :height => match_data[2],
              :x => match_data[3],
              :y => match_data[4],
              :gravity => match_data[5]
            }
          }
        end
      end
    end
  end
  
end