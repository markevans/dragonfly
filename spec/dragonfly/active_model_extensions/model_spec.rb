require File.dirname(__FILE__) + '/spec_helper'

describe Item do

  # See extra setup in models / initializer files

  describe "defining accessors" do

    let(:app1){ Dragonfly[:images] }
    let(:app2){ Dragonfly[:videos] }

    it "should return the mapping of apps to attributes" do
      app1.define_macro(model_class, :image_accessor)
      app2.define_macro(model_class, :video_accessor)
      Item.class_eval do
        image_accessor :preview_image
        video_accessor :trailer_video
      end
      Item.dragonfly_apps_for_attributes.should == {:preview_image => app1, :trailer_video => app2}
    end

    it "should work for included modules (e.g. Mongoid::Document)" do
      mongoid_document = Module.new
      app1.define_macro_on_include(mongoid_document, :dog_accessor)
      model_class = Class.new do
        def self.before_save(*args); end
        def self.before_destroy(*args); end
        include mongoid_document
        dog_accessor :doogie
      end
      model_class.dragonfly_apps_for_attributes.should == {:doogie => app1}
    end

  end

  describe "correctly defined" do

    before(:each) do
      @app = Dragonfly[:images]
      @app.define_macro(model_class, :image_accessor)
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

    describe "when the uid is set manually" do
      before(:each) do
        @item.preview_image_uid = 'some_known_uid'
      end
      it "should not try to retrieve any data" do
        @app.datastore.should_not_receive(:retrieve)
        @item.save!
      end
      it "should not try to destroy any data" do
        @app.datastore.should_not_receive(:destroy)
        @item.save!
      end
      it "should not try to store any data" do
        @app.datastore.should_not_receive(:store)
        @item.save!
      end
    end

    describe "when there has been some thing assigned but not saved" do
      before(:each) do
        @item.preview_image = "DATASTRING"
      end
      it "the reader should return an attachment" do
        @item.preview_image.should be_a(Dragonfly::ActiveModelExtensions::Attachment)
      end
      it "the uid should be nil" do
        @item.preview_image_uid.should be_nil
      end
      it "should store the image when saved" do
        @app.datastore.should_receive(:store).with(a_temp_object_with_data("DATASTRING"), {})
        @item.save!
      end
      it "should not try to destroy anything on destroy" do
        @app.datastore.should_not_receive(:destroy)
        @item.destroy
      end
      it "should return nil for the url" do
        @item.preview_image.url.should be_nil
      end
      describe "when the uid is set manually" do
        before(:each) do
          @item.preview_image_uid = 'some_known_uid'
        end
        it "should not try to retrieve any data" do
          @app.datastore.should_not_receive(:retrieve)
          @item.save!
        end
        it "should not try to destroy any data" do
          @app.datastore.should_not_receive(:destroy)
          @item.save!
        end
        it "should not try to store any data" do
          @app.datastore.should_not_receive(:store)
          @item.save!
        end
      end

    end

    describe "when something has been assigned and saved" do

      before(:each) do
        @item.preview_image = "DATASTRING"
        @app.datastore.should_receive(:store).with(a_temp_object_with_data("DATASTRING"), {}).once.and_return('some_uid')
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
        @app.should_receive(:url_for).with(an_instance_of(Dragonfly::Job)).and_return('some.url')
        @item.preview_image.url.should == 'some.url'
      end

      it "should destroy the old data when the uid is set manually" do
        @app.datastore.should_receive(:destroy).with('some_uid')
        @item.preview_image_uid = 'some_known_uid'
        @item.save!
      end

      describe "when accessed by a new model object" do
        before(:each) do
          @item = Item.find(@item.id)
        end
        it "should destroy the data on destroy" do
          @app.datastore.should_receive(:destroy).with(@item.preview_image_uid)
          @item.destroy
        end
      end

      describe "when something new is assigned" do
        before(:each) do
          @item.preview_image = "ANEWDATASTRING"
          @app.datastore.stub!(:store).and_return('some_uid')
        end
        it "should set the uid to nil" do
          @item.preview_image_uid.should be_nil
        end
        it "should destroy the old data when saved" do
          @app.datastore.should_receive(:destroy).with('some_uid')
          @item.save!
        end
        it "should not try to destroy the old data if saved again" do
          @app.datastore.should_receive(:destroy).with('some_uid')
          @item.save!
          @app.datastore.should_not_receive(:destroy).with('some_uid')
          @item.save!
        end
        it "should destroy the old data when saved, even if yet another thing is assigned" do
          @item.preview_image = "YET ANOTHER DATA STRING"
          @app.datastore.should_receive(:destroy).with('some_uid')
          @item.save!
        end
        it "should store the new data when saved" do
          @app.datastore.should_receive(:store).with(a_temp_object_with_data("ANEWDATASTRING"), {})
          @item.save!
        end
        it "should destroy the old data on destroy" do
          @app.datastore.should_receive(:destroy).with('some_uid')
          @item.destroy
        end
        it "should destroy the old data on destroy, even if yet another thing is assigned" do
          @item.preview_image = "YET ANOTHER DATA STRING"
          @app.datastore.should_receive(:destroy).with('some_uid')
          @item.destroy
        end
        it "should destroy the old data when the uid has been set manually" do
          @app.datastore.should_receive(:destroy).with('some_uid')
          @item.preview_image_uid = 'some_known_uid'
          @item.save!
        end
        it "should return the new size" do
          @item.preview_image.size.should == 14
        end
        it "should return the new data" do
          @item.preview_image.data.should == 'ANEWDATASTRING'
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
          @item.preview_image.should be_nil
        end
        it "should destroy the old data on destroy" do
          @app.datastore.should_receive(:destroy).with('some_uid')
          @item.destroy
        end
      end

      describe "when the data can't be found" do
        it "should log a warning if the data wasn't found on destroy" do
          @app.datastore.should_receive(:destroy).with('some_uid').and_raise(Dragonfly::DataStorage::DataNotFound)
          @app.log.should_receive(:warn)
          @item.destroy
        end
      end

    end

    describe "other types of assignment" do
      before(:each) do
        @app.generator.add :egg do
          "Gungedin"
        end
        @app.processor.add :doogie do |temp_object|
          temp_object.data.upcase
        end
      end

      describe "assigning with a job" do
        before(:each) do
          @job = @app.generate(:egg)
          @item.preview_image = @job
        end

        it "should work" do
          @item.preview_image.data.should == 'Gungedin'
        end

        it "should not be affected by subsequent changes to the job" do
          @job.process!(:doogie)
          @item.preview_image.data.should == 'Gungedin'
        end
      end

      describe "assigning with another attachment" do
        before(:each) do
          Item.class_eval do
            image_accessor :other_image
          end
        end
        it "should work like assigning the job" do
          @item.preview_image = 'eggheads'
          @item.other_image = @item.preview_image
          @item.preview_image = 'dogchin'
          @item.other_image.data.should == 'eggheads'
        end
      end

      describe "assigning by means of a bang method" do
        before(:each) do
          @app.processor.add :double do |temp_object|
            temp_object.data * 2
          end
          @app.encoder.add do |temp_object, format|
            temp_object.data.downcase + format.to_s
          end
          @item.preview_image = "HELLO"
        end
        it "should modify as if being assigned again" do
          @item.preview_image.process!(:double)
          @item.preview_image.data.should == 'HELLOHELLO'
        end
        it "should update the magic attributes" do
          @item.preview_image.process!(:double)
          @item.preview_image_size.should == 10
        end
        it "should work for encode" do
          @item.preview_image.encode!(:egg)
          @item.preview_image.data.should == 'helloegg'
        end
        it "should work repeatedly" do
          @item.preview_image.process!(:double).encode!(:egg)
          @item.preview_image.data.should == 'hellohelloegg'
          @item.preview_image_size.should == 13
        end
      end
    end

  end

  describe "validations" do

    before(:all) do
      @app = Dragonfly[:images]
      @app.define_macro(model_class, :image_accessor)
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

    describe "validates_property" do

      before(:each) do
        @item = Item.new(:preview_image => "1234567890")
      end

      before(:all) do
        custom_analyser = Class.new do
          def mime_type(temp_object)
            case temp_object.data
            when "WRONG TYPE" then 'wrong/type'
            when "OTHER TYPE" then nil
            else 'how/special'
            end
          end

          def number_of_Gs(temp_object)
            temp_object.data.count('G')
          end
        end
        @app.analyser.register(custom_analyser)

        Item.class_eval do
          validates_property :mime_type, :of => :preview_image, :in => ['how/special', 'how/crazy'], :if => :its_friday
          validates_property :mime_type, :of => [:other_image, :yet_another_image], :as => 'how/special'
          validates_property :number_of_Gs, :of => :preview_image, :in => (0..2)
          validates_property :mime_type, :of => :otra_imagen, :in => ['que/pasa', 'illo/tio'], :message => "tipo de contenido incorrecto. Que chungo tio"

          image_accessor :preview_image
          image_accessor :other_image
          image_accessor :yet_another_image
          image_accessor :otra_imagen

          def its_friday
            true
          end

        end
      end

      it "should be valid if nil, if not validated on presence (even with validates_property)" do
        @item.other_image = nil
        @item.should be_valid
      end

      it "should be invalid if the property is nil" do
        @item.preview_image = "OTHER TYPE"
        @item.should_not be_valid
        @item.errors[:preview_image].should match_ar_error("mime type is incorrect. It needs to be one of 'how/special', 'how/crazy', but was ''")
      end

      it "should be invalid if the property is wrong" do
        @item.preview_image = "WRONG TYPE"
        @item.should_not be_valid
        @item.errors[:preview_image].should match_ar_error("mime type is incorrect. It needs to be one of 'how/special', 'how/crazy', but was 'wrong/type'")
      end

      it "should work for a range" do
        @item.preview_image = "GOOGLE GUM"
        @item.should_not be_valid
        @item.errors[:preview_image].should match_ar_error("number of gs is incorrect. It needs to be between 0 and 2, but was '3'")
      end

      it "should validate individually" do
        @item.other_image = "1234567"
        @item.yet_another_image = "WRONG TYPE"
        @item.should_not be_valid
        @item.errors[:other_image].should match_ar_error(nil)
        @item.errors[:yet_another_image].should match_ar_error("mime type is incorrect. It needs to be 'how/special', but was 'wrong/type'")
      end

      it "should include standard extra options like 'if' on mime type validation" do
        @item.should_receive(:its_friday).and_return(false)
        @item.preview_image = "WRONG TYPE"
        @item.should be_valid
      end

      it "should require either :as or :in as an argument" do
        lambda{
          Item.class_eval do
            validates_property :mime_type, :of => :preview_image
          end
        }.should raise_error(ArgumentError)
      end

      it "should require :of as an argument" do
        lambda{
          Item.class_eval do
            validates_property :mime_type, :as => 'hi/there'
          end
        }.should raise_error(ArgumentError)
      end

      it "should allow for custom messages" do
        @item.otra_imagen = "WRONG TYPE"
        @item.should_not be_valid
        @item.errors[:otra_imagen].should match_ar_error("tipo de contenido incorrecto. Que chungo tio")
      end

    end

  end

  describe "extra properties" do

    before(:each) do
      @app = Dragonfly[:images]
      custom_analyser = Class.new do
        def some_analyser_method(temp_object)
          "abc" + temp_object.data[0..0]
        end
        def number_of_As(temp_object); temp_object.data.count('A'); end
      end
      @app.analyser.register(custom_analyser)
      @app.define_macro(model_class, :image_accessor)
      Item.class_eval do
        image_accessor :preview_image
      end
      @item = Item.new
    end

    describe "magic attributes" do

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

      it "should store the original file name if it exists" do
        data = 'jasdlkf sadjl'
        data.stub!(:original_filename).and_return('hello.png')
        @item.preview_image = data
        @item.preview_image_name.should == 'hello.png'
      end
    end


    describe "delegating methods to the job" do
      before(:each) do
        @item.preview_image = "DATASTRING"
      end
      it "should have properties from the analyser" do
        @item.preview_image.number_of_As.should == 2
      end
      it "should report that it responds to analyser methods" do
        @item.preview_image.respond_to?(:number_of_As).should be_true
      end
      it "should include analyser methods in methods" do
        @item.preview_image.methods.include?('number_of_As'.to_method_name).should be_true
      end
      it "should include analyser methods in public_methods" do
        @item.preview_image.public_methods.include?('number_of_As'.to_method_name).should be_true
      end

      it "should update when something new is assigned" do
        @item.preview_image = 'ANEWDATASTRING'
        @item.preview_image.number_of_As.should == 3
      end

      describe "from a new model object" do
        before(:each) do
          @app.datastore.stub!(:store).and_return('my_uid')
          item = Item.create!(:preview_image => 'DATASTRING')
          @item = Item.find(item.id)
        end
        it "should load the content then delegate the method" do
          @app.datastore.should_receive(:retrieve).with('my_uid').and_return(['DATASTRING', {}])
          @item.preview_image.number_of_As.should == 2
        end
        it "should use the magic attribute if there is one, and not load the content" do
          @app.datastore.should_not_receive(:retrieve)
          @item.should_receive(:preview_image_some_analyser_method).and_return('result yo')
          @item.preview_image.some_analyser_method.should == 'result yo'
        end

        %w(size name ext).each do |attr|
          it "should use the magic attribute for #{attr} if there is one, and not load the content" do
            @app.datastore.should_not_receive(:retrieve)
            @item.should_receive("preview_image_#{attr}".to_sym).and_return('result yo')
            @item.preview_image.send(attr).should == 'result yo'
          end

          it "should load the content then delegate '#{attr}' if there is no magic attribute for it" do
            @item.should_receive(:public_methods).and_return(['preview_image_uid']) # no magic attributes
            @app.datastore.should_receive(:retrieve).with('my_uid').and_return(['DATASTRING', {}])
            @item.preview_image.send(attr).should == @item.preview_image.send(:job).send(attr)
          end
        end

      end

      it "should not raise an error if a non-existent method is called" do
        # Just checking method missing works ok
        lambda{
          @item.preview_image.eggbert
        }.should raise_error(NoMethodError)
      end
    end
  end

  describe "inheritance" do

    before(:all) do
      @app = Dragonfly[:images]
      @app2 = Dragonfly[:egg]
      @app.define_macro(model_class, :image_accessor)
      @app2.define_macro(model_class, :egg_accessor)
      Car.class_eval do
        image_accessor :image
      end
      Photo.class_eval do
        egg_accessor :image
      end

      @base_class = Car
      class ReliantRobin < Car; image_accessor :reliant_image; end
      @subclass = ReliantRobin
      class ReliantRobinWithModule < Car
        include Module.new
        image_accessor :reliant_image
      end
      @subclass_with_module = ReliantRobinWithModule
      @unrelated_class = Photo
    end

    it "should allow assigning base class accessors" do
      @base_class.create! :image => 'blah'
    end
    it "should not allow assigning subclass accessors in the base class" do
      @base_class.new.should_not respond_to(:reliant_image=)
    end
    it "should allow assigning base class accessors in the subclass" do
      @subclass.create! :image => 'blah'
    end
    it "should allow assigning subclass accessors in the subclass" do
      @subclass.create! :reliant_image => 'blah'
    end
    it "should allow assigning base class accessors in the subclass, even if it has mixins" do
      @subclass_with_module.create! :image => 'blah'
    end
    it "should allow assigning subclass accessors in the subclass, even if it has mixins" do
      @subclass_with_module.create! :reliant_image => 'blah'
    end
    it "return the correct apps for each accessors, even when names clash" do
      @base_class.dragonfly_apps_for_attributes.should == {:image => @app}
      @subclass.dragonfly_apps_for_attributes.should == {:image => @app, :reliant_image => @app}
      @subclass_with_module.dragonfly_apps_for_attributes.should == {:image => @app, :reliant_image => @app}
      @unrelated_class.dragonfly_apps_for_attributes.should == {:image => @app2}
    end
  end

end