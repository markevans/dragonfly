require File.dirname(__FILE__) + '/../spec_helper'

describe "Deprecated stuff" do

  describe "job urls" do
    
    before(:each) do
      @app = test_app.configure_with(:rmagick) do |c|
        c.log = Logger.new($stdout)
      end
      @job = @app.fetch('eggs')
    end
    
    it { @job.url(:gif).should == @job.gif.url }
    it { @job.url('20x20').should == @job.thumb('20x20').url }
    it { @job.url('20x20', :gif).should == @job.thumb('20x20', :gif).url }

  end

end
