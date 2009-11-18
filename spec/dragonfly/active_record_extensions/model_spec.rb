require File.dirname(__FILE__) + '/spec_helper'

describe Item do

  # See extra setup in models / initializer files

  describe "registering dragonfly apps" do

    before(:each) do
      @app1, @app2 = Dragonfly::App[:images], Dragonfly::App[:videos]
      ActiveRecord::Base.register_dragonfly_app(:image, @app1)
      ActiveRecord::Base.register_dragonfly_app(:video, @app2)
    end

    it "should return the mapping of apps to attributes" do
      Item.class_eval do
        image_accessor :preview_image
        video_accessor :trailer_video
      end
      Item.dragonfly_apps_for_attributes.should == {:preview_image => @app1, :trailer_video => @app2}
    end

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
        @app = Dragonfly::App[:images]
        ActiveRecord::Base.register_dragonfly_app(:image, @app)
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
        it "should not try to destroy anything on destroy" do
          @app.datastore.should_not_receive(:destroy)
          @item.destroy
        end
      end
      
      describe "when there has been some thing assigned but not saved" do
        before(:each) do
          @item.preview_image = "DATASTRING"
        end
        it "the reader should return an attachment" do
          @item.preview_image.should be_a(Dragonfly::ActiveRecordExtensions::Attachment)
        end
        it "the uid should be a 'pending' object" do
          @item.preview_image_uid.should be_a(Dragonfly::ActiveRecordExtensions::PendingUID)
        end
        it "should store the image when saved" do
          @app.datastore.should_receive(:store).with(a_temp_object_with_data("DATASTRING"))
          @item.save!
        end
        it "should not try to destroy anything on destroy" do
          @app.datastore.should_not_receive(:destroy)
          @item.destroy
        end
        it "should return nil for the url" do
          @item.preview_image.url.should be_nil
        end
        it "should return the size" do
          @item.preview_image.size.should == 10
        end
        it "should return the temp_object" do
          temp_object = @item.preview_image.temp_object
          temp_object.should be_a(Dragonfly::ExtendedTempObject)
          temp_object.data.should == 'DATASTRING'
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
        
        it "should destroy the data on destroy" do
          @app.datastore.should_receive(:destroy).with('some_uid')
          @item.destroy
        end

        it "should return the url for the data" do
          @app.should_receive(:url_for).with(@item.preview_image_uid, :arg).and_return('some.url')
          @item.preview_image.url(:arg).should == 'some.url'
        end
        
        describe "when reloaded" do
          before(:each) do
            @item.reload
          end
          it "should destroy the data on destroy" do
            @app.datastore.should_receive(:destroy).with(@item.preview_image_uid)
            @item.destroy
          end
          it "should return the size" do
            @item.preview_image.size.should == 10
          end
          it "should return the temp_object" do
            temp_object = @item.preview_image.temp_object
            temp_object.should be_a(Dragonfly::ExtendedTempObject)
            temp_object.data.should == 'DATASTRING'
          end
        end

        describe "when something new is assigned" do
          before(:each) do
            @item.preview_image = "NEWDATASTRING"
          end
          it "should set the uid to pending" do
            @item.preview_image_uid.should be_a(Dragonfly::ActiveRecordExtensions::PendingUID)
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
          it "should destroy the old data on destroy" do
            @app.datastore.should_receive(:destroy).with('some_uid')
            @item.destroy
          end
          it "should return the new size" do
            @item.preview_image.size.should == 13
          end
          it "should return the new temp_object" do
            temp_object = @item.preview_image.temp_object
            temp_object.should be_a(Dragonfly::ExtendedTempObject)
            temp_object.data.should == 'NEWDATASTRING'
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
          it "should destroy the old data on destroy" do
            @app.datastore.should_receive(:destroy).with('some_uid')
            @item.destroy
          end
        end

        describe "when the data can't be found" do
          before(:each) do
            @app.datastore.stub!(:destroy).with('some_uid').and_raise(Dragonfly::DataStorage::DataNotFound)
            @app.datastore.stub!(:retrieve).with('some_uid').and_raise(Dragonfly::DataStorage::DataNotFound)
          end
          it "should log a warning if the data wasn't found on destroy" do
            @app.log.should_receive(:warn)
            @item.destroy
          end 
        end

      end

    end
  end  

  describe "validations" do

    before(:all) do
      @app = Dragonfly::App[:images]
      ActiveRecord::Base.register_dragonfly_app(:image, @app)
    end
    
    describe "validates_presence_of" do

      before(:all) do
        Item.class_eval do
          image_accessor :preview_image
          validates_presence_of :preview_image
        end
      end

      it "should be valid if set" do
        Item.new(:preview_image => "1234567890").should be_valid
      end

      it "should be invalid if not set" do
        Item.new.should_not be_valid
      end

    end
    
    describe "validates_size_of" do
      
      before(:all) do
        Item.class_eval do
          image_accessor :preview_image
          validates_size_of :preview_image, :within => (6..10)
        end
      end

      it "should be valid if ok" do
        Item.new(:preview_image => "1234567890").should be_valid
      end

      it "should be invalid if too small" do
        Item.new(:preview_image => "12345").should_not be_valid
      end
      
    end
    
    describe "validates_mime_type_of" do

      before(:each) do
        @item = Item.new(:preview_image => "1234567890")
      end

      before(:all) do
        custom_analyser = Object.new
        def custom_analyser.mime_type(temp_object)
          case temp_object.data
          when "WRONG TYPE" then 'wrong/type'
          when "OTHER TYPE" then nil
          else 'how/special'
          end
        end
        @app.analyser.register(custom_analyser)
        
        Item.class_eval do
          validates_mime_type_of :preview_image, :in => ['how/special', 'how/crazy'], :if => :its_friday
          validates_mime_type_of :other_image, :yet_another_image, :as => 'how/special'

          image_accessor :preview_image
          image_accessor :other_image
          image_accessor :yet_another_image

          def its_friday
            true
          end

        end
      end
    
      it "should be valid if nil, if not validated on presence (even with validates_mime_type_of)" do
        @item.other_image = nil
        @item.should be_valid
      end
    
      it "should be invalid if the mime_type is unknown" do
        @item.preview_image = "OTHER TYPE"
        @item.should_not be_valid
        @item.errors.on(:preview_image).should == "doesn't have the correct MIME-type. It needs to be one of 'how/special', 'how/crazy', but was 'unknown'"
      end

      it "should be invalid if the mime_type is wrong" do
        @item.preview_image = "WRONG TYPE"
        @item.should_not be_valid
        @item.errors.on(:preview_image).should == "doesn't have the correct MIME-type. It needs to be one of 'how/special', 'how/crazy', but was 'wrong/type'"
      end

      it "should validate individually" do
        @item.other_image = "1234567"
        @item.yet_another_image = "WRONG TYPE"
        @item.should_not be_valid
        @item.errors.on(:other_image).should be_nil
        @item.errors.on(:yet_another_image).should == "doesn't have the correct MIME-type. It needs to be 'how/special', but was 'wrong/type'"
      end

      it "should include standard extra options like 'if' on mime type validation" do
        @item.should_receive(:its_friday).and_return(false)
        @item.preview_image = "WRONG TYPE"
        @item.should be_valid
      end
    
      it "should require either :as or :in as an argument" do
        lambda{
          Item.class_eval do
            validates_mime_type_of :preview_image
          end
        }.should raise_error(ArgumentError)
      end

    end

  end

  describe "magic attributes" do
    
    before(:each) do
      @app = Dragonfly::App[:images]
      custom_analyser = Object.new
      def custom_analyser.some_analyser_method(temp_object)
        "abc" + temp_object.data[0..0]
      end
      @app.analyser.register(custom_analyser)
      ActiveRecord::Base.register_dragonfly_app(:image, @app)
      Item.class_eval do
        image_accessor :preview_image
      end
      @item = Item.new
    end
    
    it "should default the magic attribute as nil" do
      @item.preview_image_some_analyser_method.should be_nil
    end
    
    it "should set the magic attribute when assigned" do
      @item.preview_image = '123'
      @item.preview_image_some_analyser_method.should == 'abc1'
    end
    
    it "should not set non-magic attributes with the same prefix when assigned" do
      @item.preview_image_blah_blah = 'wassup'
      @item.preview_image = '123'
      @item.preview_image_blah_blah.should == 'wassup'
    end
    
    it "should update the magic attribute when something else is assigned" do
      @item.preview_image = '123'
      @item.preview_image = '456'
      @item.preview_image_some_analyser_method.should == 'abc4'
    end
    
    it "should reset the magic attribute when set to nil" do
      @item.preview_image = '123'
      @item.preview_image = nil
      @item.preview_image_some_analyser_method.should be_nil
    end
    
    it "should not reset non-magic attributes with the same prefix when set to nil" do
      @item.preview_image_blah_blah = 'wassup'
      @item.preview_image = '123'
      @item.preview_image = nil
      @item.preview_image_blah_blah.should == 'wassup'
    end
    
    it "should work for size too" do
      @item.preview_image = '123'
      @item.preview_image_size.should == 3
    end
    
    it "should store the original file extension if it exists" do
      data = 'jasdlkf sadjl'
      data.stub!(:original_filename).and_return('hello.png')
      @item.preview_image = data
      @item.preview_image_ext.should == 'png'
    end
    
  end

end