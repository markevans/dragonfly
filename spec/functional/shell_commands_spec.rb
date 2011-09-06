require 'spec_helper'

describe "a configured imagemagick app" do
  
  before(:each) do
    @app = test_app.configure_with(:imagemagick)
  end
  
  describe "shell injection" do
    
    it "should not allow it!" do
      begin
        suppressing_stderr do
          @app.generate(:plain, 10, 10, 'white').convert("-resize 5x5 ; touch tmp/stuff").apply
        end
      rescue Dragonfly::FunctionManager::UnableToHandle
      end
      File.exist?('tmp/stuff').should be_false
    end
    
  end
  
end