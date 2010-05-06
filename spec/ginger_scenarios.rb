require 'ginger'

Ginger.configure do |config|
  config.aliases["active_record"] = "activerecord" # Because the gem name is 'activerecord', but the require is 'active_record'
  
  activerecord_2_3_5 = Ginger::Scenario.new("ActiveRecord 2.3.5")
  activerecord_2_3_5[/^active_?record$/] = "2.3.5"
  
  activerecord_3_0_0 = Ginger::Scenario.new("ActiveRecord 3.0.0 beta3")
  activerecord_3_0_0[/^active_?record$/] = "3.0.0.beta3"
  
  config.scenarios << activerecord_2_3_5 << activerecord_3_0_0
end
