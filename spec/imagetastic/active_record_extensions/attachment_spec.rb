require File.dirname(__FILE__) + '/spec_helper'

describe Imagetastic::ActiveRecordExtensions::Attachment do
  
  before(:each) do
    @store = mock('store', :store => nil, :retrieve => nil, :destroy => nil)
    @app = mock('app', :datastore => @store)
    @parent_model = mock('model')
    @attachment = Imagetastic::ActiveRecordExtensions::Attachment.new(@app, @parent_model)
  end
  
  describe "#save" do
    
    describe "when there is nothing assigned" do
      it "should not try to store anything" do
        @store.should_not_receive(:store)
        @attachment.save!
      end
    end
    
    describe "when there is something assigned" do
      
      before(:each) do
        @temp_object = mock('temp_object')
        Imagetastic::TempObject.stub!(:new).with("DATASTRING").and_return(@temp_object)
        @attachment.assign("DATASTRING")
      end
      
      it "should store it on save" do
        @store.should_receive(:store).with(@temp_object)
        @attachment.save!
      end
      
      it "should do nothing if no change" do
        @attachment.save!
        
        @store.should_not_receive(:store)
        @store.should_not_receive(:destroy)
        @attachment.save!
      end
      
      it "should not try to destroy any data when nothing previously assigned" do
        @store.should_not_receive(:destroy)
        @attachment.save!
      end
      
      it "should destroy the old data when previously assigned" do
        @store.should_receive(:store).with(@temp_object).and_return('some_uid')
        @attachment.save!
        
        Imagetastic::TempObject.stub!(:new)
        @attachment.assign("NEWDATASTRING")
        @store.should_receive(:destroy).with('some_uid')
        @attachment.save!
      end
    end
    
  end
  
end