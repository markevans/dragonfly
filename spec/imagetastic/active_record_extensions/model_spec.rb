require File.dirname(__FILE__) + '/spec_helper'

describe Item do

  # See extra setup in models / initializer files

  it "should return the attribute - app mappings" do
    app1, app2 = Imagetastic::App.new, Imagetastic::App.new
    ActiveRecord::Base.register_imagetastic_app(:image, app1)
    ActiveRecord::Base.register_imagetastic_app(:video, app2)
    Item.class_eval do
      image_accessor :preview_image
      video_accessor :trailer_video
    end
    Item.attachment_app_mappings.should == {:preview_image => app1, :trailer_video => app2}
  end
  
  describe "defining accessors" do

    it "should raise an error if the wrong method prefix is used" do
      lambda{
        Item.class_eval do
          dog_accessor :preview_image
        end
      }.should raise_error(NameError)
    end

    describe "correctly defined" do
    
      before(:each) do
        @app = Imagetastic::App.new
        ActiveRecord::Base.register_imagetastic_app(:image, @app)
        Item.class_eval do
          image_accessor :preview_image
        end
        @item = Item.new
        @attachment = mock('attachment', :assign => nil)
        Imagetastic::ActiveRecordExtensions::Attachment.stub!(:new).with(@app).and_return(@attachment)
      end    

      describe "reader" do

        it "should provide a reader" do
          @item.should respond_to(:preview_image)
        end
      
        it "should delegate to attachment.to_value" do
          result = mock('result')
          @attachment.should_receive(:to_value).and_return(result)
          @item.preview_image.should == result
        end
        
      end
  
      describe "writer" do

        it "should provide a writer" do
          @item.should respond_to(:preview_image=)
        end

        it "should assign to the attachment when assigned" do
          @attachment.should_receive(:assign).with("IMAGESTRING")
          @item.preview_image = "IMAGESTRING"
        end

        it "should not call save on the attachment if not saved" do
          @attachment.should_not_receive(:save)
          @item.preview_image = "IMAGESTRING"
        end

        it "should call save on the attachment when saved" do
          @item.preview_image = "IMAGESTRING"
          @attachment.should_receive(:save)
          @item.save!
        end
        
        it "should not call save on the attachment if not assigned" do
          @attachment.should_not_receive(:save)
          @item.save!
        end

      end
      
      describe "monitoring changes" do
        
        before(:each) do
          pending
        end
        
        it "should correctly return the normal change methods when unchanged" do
          @item.changed?.should be_false
          @item.changes.should == {}
          @item.preview_image_changed?.should be_false
          @item.preview_image_was.should == @item.preview_image
          @item.preview_image_change.should be_nil
        end
        
        it "should correctly return the normal change methods when changed" do
          @item.preview_image = "IMAGESTRING"
          
          @item.changed?.should be_true
          @item.changes.should == {'preview_image' => [nil, @attachment]}
          @item.preview_image_changed?.should be_true
          @item.preview_image_was.should be_nil
          @item.preview_image_change.should == [nil, @attachment]
        end
        
        it "should correctly return the normal change methods when changed after save" do
          @item.preview_image = "IMAGESTRING"
          @item.save!
          
          @item.changed?.should be_false
          @item.changes.should == {}
          @item.preview_image_changed?.should be_false
          @item.preview_image_was.should == @item.preview_image
          @item.preview_image_change.should be_nil
        end
        
        it "should correctly respond to the .._will_change! method" do
          @item.preview_image = "IMAGESTRING"
          @item.save!
          
          @item.preview_image_will_change!
          @item.preview_image.destroy
          
          @item.preview_image_changed?.should be_true
        end
      end
    
    end

  end  
end