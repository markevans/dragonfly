require 'ginger'

Ginger.configure do |config|
  config.aliases["active_record"] = "activerecord" # Because the gem name is 'activerecord', but the require is 'active_record'
  config.aliases["active_model"] = "activemodel"
  
  activerecord_2_3_5 = Ginger::Scenario.new("ActiveRecord 2.3.5")
  activerecord_2_3_5[/^active_?record$/] = "2.3.5"
  
  activemodel_3_0_0 = Ginger::Scenario.new("ActiveModel 3.0.0 beta4")
  activemodel_3_0_0['activemodel'] = "3.0.0.beta4"
  
  config.scenarios << activerecord_2_3_5 << activemodel_3_0_0
end
