require File.dirname(__FILE__) + '/../../spec_helper'

begin
  require 'active_model'
rescue LoadError => e
  # When there's NO active_model
  require File.dirname(__FILE__) + '/active_record_setup'
else
  # When there IS active model
  require File.dirname(__FILE__) + '/active_model_setup'
end
