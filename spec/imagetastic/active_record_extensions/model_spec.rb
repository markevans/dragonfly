require File.dirname(__FILE__) + '/spec_helper'

describe Item do

  # See extra setup in models / initializer files

  it "should return the registered imagetastic apps" do
    app1, app2 = Imagetastic::App.new, Imagetastic::App.new
    ActiveRecord::Base.register_imagetastic_app(:image, app1)
    ActiveRecord::Base.register_imagetastic_app(:video, app2)
    Item.class_eval do
      image_accessor :preview_image
      video_accessor :trailer_video
    end
    Item.registered_imagetastic_apps.should == {:preview_image => app1, :trailer_video => app2}
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
      end    

      it "should provide a reader" do
        @item.should respond_to(:preview_image)
      end

      it "should provide a writer" do
        @item.should respond_to(:preview_image=)
      end

      describe "when there has been nothing assigned" do
        it "the reader should return nil" do
          @item.preview_image.should be_nil
        end
        it "the uid should be nil" do
          @item.preview_image_uid.should be_nil
        end
        it "should not try to store anything on save" do
          @app.datastore.should_not_receive(:store)
          @item.save!
        end
        it "should not try to destroy anything on save" do
          @app.datastore.should_not_receive(:destroy)
          @item.save!
        end
      end
      
      describe "when there has been some thing assigned but not saved" do
        before(:each) do
          @item.preview_image = "DATASTRING"
        end
        it "the reader should return an attachment" do
          @item.preview_image.should be_a(Imagetastic::ActiveRecordExtensions::Attachment)
        end
        it "the uid should be a 'pending' object" do
          @item.preview_image_uid.should be_a(Imagetastic::ActiveRecordExtensions::PendingUID)
        end
        it "should store the image when saved" do
          @app.datastore.should_receive(:store).with(a_temp_object_with_data("DATASTRING"))
          @item.save!
        end
      end
      
      describe "when something has been assigned and saved" do

        before(:each) do
          @item.preview_image = "DATASTRING"
          @app.datastore.should_receive(:store).with(a_temp_object_with_data("DATASTRING")).once.and_return('some_uid')
          @app.datastore.stub!(:store)
          @app.datastore.stub!(:destroy)
          @item.save!
        end
        it "should have the correct uid" do
          @item.preview_image_uid.should == 'some_uid'
        end
        it "should not try to store anything if saved again" do
          @app.datastore.should_not_receive(:store)
          @item.save!
        end

        it "should not try to destroy anything if saved again" do
          @app.datastore.should_not_receive(:destroy)
          @item.save!
        end

        describe "when something new is assigned" do
          before(:each) do
            @item.preview_image = "NEWDATASTRING"
          end
          it "should set the uid to pending" do
            @item.preview_image_uid.should be_a(Imagetastic::ActiveRecordExtensions::PendingUID)
          end
          it "should destroy the old data when saved" do
            @app.datastore.should_receive(:store).with(a_temp_object_with_data("NEWDATASTRING")).once.and_return('some_uid')
            
            @app.datastore.should_receive(:destroy).with('some_uid')
            @item.save!
          end
          it "should store the new data when saved" do
            @app.datastore.should_receive(:store).with(a_temp_object_with_data("NEWDATASTRING"))
            @item.save!
          end
        end
        
        describe "when it is set to nil" do
          before(:each) do
            @item.preview_image = nil
          end
          it "should set the uid to nil" do
            @item.preview_image_uid.should be_nil
          end
          it "should return the attribute as nil" do
            @item.preview_image.should be_nil
          end
          it "should destroy the data on save" do
            @app.datastore.should_receive(:destroy).with('some_uid')
            @item.save!
          end
        end

      end

    end
  end  
end