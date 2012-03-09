require 'dragonfly/active_model_extensions/spec_helper'

describe Item do

  def set_up_item_class(app=test_app)
    app.define_macro(MyModel, :image_accessor)
    Item.class_eval do
      image_accessor :preview_image
    end
  end

  # See extra setup in models / initializer files

  describe "defining accessors" do

    let(:app1){ Dragonfly[:img] }
    let(:app2){ Dragonfly[:vid] }

    describe "attachment classes" do
      before(:each) do
        app1.define_macro(MyModel, :image_accessor)
        app2.define_macro(MyModel, :video_accessor)
        Item.class_eval do
          image_accessor :preview_image
          video_accessor :trailer_video
        end
        @classes = Item.dragonfly_attachment_classes
        @class1, @class2 = @classes
      end
      
      it "should return the attachment classes" do
        @class1.superclass.should == Dragonfly::ActiveModelExtensions::Attachment
        @class2.superclass.should == Dragonfly::ActiveModelExtensions::Attachment
      end

      it "should associate the correct app with each class" do
        @class1.app.should == app1
        @class2.app.should == app2
      end

      it "should associate the correct attribute with each class" do
        @class1.attribute.should == :preview_image
        @class2.attribute.should == :trailer_video
      end

      it "should associate the correct model class with each class" do
        @class1.model_class.should == Item
        @class2.model_class.should == Item
      end
    end

    describe "included modules (e.g. Mongoid::Document)" do
      
      it "should work" do
        mongoid_document = Module.new
        app1.define_macro_on_include(mongoid_document, :dog_accessor)
        model_class = Class.new do
          def self.before_save(*args); end
          def self.before_destroy(*args); end
          include mongoid_document
          dog_accessor :doogie
        end
        klass = model_class.dragonfly_attachment_classes.first
        klass.app.should == app1
        klass.attribute.should == :doogie
      end

      it "should work with two apps" do
        mongoid_document = Module.new
        app1.define_macro_on_include(mongoid_document, :image_accessor)
        app2.define_macro_on_include(mongoid_document, :video_accessor)
        model_class = Class.new do
          def self.before_save(*args); end
          def self.before_destroy(*args); end
          include mongoid_document
          image_accessor :doogie
          video_accessor :boogie
        end
        model_class.dragonfly_attachment_classes[0].app.should == app1
        model_class.dragonfly_attachment_classes[1].app.should == app2
      end

    end

  end

  describe "correctly defined" do

    before(:each) do
      @app = test_app
      @app.define_macro(MyModel, :image_accessor)
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
        @app.datastore.should_receive(:store).with(a_temp_object_with_data("DATASTRING"), hash_including)
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
        @app.datastore.should_receive(:store).with(a_temp_object_with_data("DATASTRING"), hash_including).once.and_return('some_uid')
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

      it "should destroy the old data when the uid is set manually" do
        @app.datastore.should_receive(:destroy).with('some_uid')
        @item.preview_image_uid = 'some_known_uid'
        @item.save!
      end

      # SEE model_urls_spec.rb for urls

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
          @app.datastore.should_receive(:store).with(a_temp_object_with_data("ANEWDATASTRING"), hash_including)
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

        it 'should mark the attribute as changed' do
          @item.preview_image_uid_changed?.should be_true
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
        
        it 'should mark the attribute as changed' do
          @item.preview_image_uid_changed?.should be_true
        end
        
      end

      describe "destroy errors" do
        it "should log a warning if the data wasn't found on destroy" do
          @app.datastore.should_receive(:destroy).with('some_uid').and_raise(Dragonfly::DataStorage::DataNotFound)
          @app.log.should_receive(:warn)
          @item.destroy
        end

        it "should log a warning if the data wasn't found on destroy" do
          @app.datastore.should_receive(:destroy).with('some_uid').and_raise(Dragonfly::DataStorage::DestroyError)
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

    describe "remote_url" do
      it "should give the remote url if the uid is set" do
        @item.preview_image_uid = 'some/uid'
        @app.should_receive(:remote_url_for).with('some/uid', :some => 'param').and_return('http://egg.nog')
        @item.preview_image.remote_url(:some => 'param').should == 'http://egg.nog'
      end
      it "should return nil if the content is not yet saved" do
        @item.preview_image = "hello"
        @item.preview_image.remote_url(:some => 'param').should be_nil
      end
    end

  end

  describe "validations" do

    before(:all) do
      @app = test_app
      @app.define_macro(MyModel, :image_accessor)
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
        @item.errors[:preview_image].should == ["mime type is incorrect. It needs to be one of 'how/special', 'how/crazy', but was 'application/octet-stream'"]
      end

      it "should be invalid if the property is wrong" do
        @item.preview_image = "WRONG TYPE"
        @item.should_not be_valid
        @item.errors[:preview_image].should == ["mime type is incorrect. It needs to be one of 'how/special', 'how/crazy', but was 'wrong/type'"]
      end

      it "should work for a range" do
        @item.preview_image = "GOOGLE GUM"
        @item.should_not be_valid
        @item.errors[:preview_image].should == ["number of gs is incorrect. It needs to be between 0 and 2, but was '3'"]
      end

      it "should validate individually" do
        @item.other_image = "1234567"
        @item.yet_another_image = "WRONG TYPE"
        @item.should_not be_valid
        @item.errors[:other_image].should == []
        @item.errors[:yet_another_image].should == ["mime type is incorrect. It needs to be 'how/special', but was 'wrong/type'"]
      end

      it "should include standard extra options like 'if' on mime type validation" do
        @item.should_receive(:its_friday).and_return(false)
        @item.preview_image = "WRONG TYPE"
        @item.should be_valid
      end

      it "should allow case sensitivity to be turned off when :as is specified" do
        @item.should_receive(:its_friday).and_return(false)
        Item.class_eval do
          validates_property :mime_type, :of => :preview_image, :as => 'WronG/TypE', :case_sensitive => false
        end
        @item.preview_image = "WRONG TYPE"
        @item.should be_valid
      end

      it "should allow case sensitivity to be turned off when :in is specified" do
        @item.should_receive(:its_friday).and_return(false)
        Item.class_eval do
          validates_property :mime_type, :of => :preview_image, :in => ['WronG/TypE'], :case_sensitive => false
        end
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
        @item.errors[:otra_imagen].should  == ["tipo de contenido incorrecto. Que chungo tio"]
      end
      
      it "should allow for custom messages including access to the property name and expected/allowed values" do
        @item.should_receive(:its_friday).and_return(false) # hack to get rid of other validation
        Item.class_eval do
          validates_property :mime_type, :of => :preview_image, :as => 'one/thing',
            :message => proc{|actual, model| "Unlucky #{model.title}! Was #{actual}" }
        end
        @item.title = 'scubby'
        @item.preview_image = "WRONG TYPE"
        @item.should_not be_valid
        @item.errors[:preview_image].should  == ["Unlucky scubby! Was wrong/type"]
      end

    end

  end

  describe "extra properties" do

    before(:each) do
      @app = test_app
      custom_analyser = Class.new do
        def some_analyser_method(temp_object)
          "abc" + temp_object.data[0..0]
        end
        def number_of_As(temp_object); temp_object.data.count('A'); end
      end
      @app.analyser.register(custom_analyser)
      @app.define_macro(MyModel, :image_accessor)
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

      it "should store the original file name if it exists" do
        data = 'jasdlkf sadjl'
        data.stub!(:original_filename).and_return('hello.png')
        @item.preview_image = data
        @item.preview_image_name.should == 'hello.png'
      end

    end

    describe "meta from magic attributes" do
      
      it "should store the meta for the original file name if it exists" do
        data = 'jasdlkf sadjl'
        data.stub!(:original_filename).and_return('hello.png')
        @item.preview_image = data
        @item.preview_image.meta[:name].should == 'hello.png'
      end
      
      it "should include magic attributes in the saved meta" do
        @item.preview_image = '123'
        @item.save!
        @app.fetch(@item.preview_image_uid).meta[:some_analyser_method].should == 'abc1'
      end

      it "should include the size in the saved meta" do
        @item.preview_image = '123'
        @item.save!
        @app.fetch(@item.preview_image_uid).meta[:size].should == 3
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
        @item.preview_image.methods.map{|m| m.to_sym }.should include(:number_of_As)
      end
      it "should include analyser methods in public_methods" do
        @item.preview_image.public_methods.map{|m| m.to_sym }.should include(:number_of_As)
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
          @item.should_receive(:preview_image_some_analyser_method).at_least(:once).and_return('result yo')
          @item.preview_image.some_analyser_method.should == 'result yo'
        end

        it "should use the magic attribute for size if there is one, and not the job object" do
          @item.preview_image.send(:job).should_not_receive(:size)
          @item.should_receive("preview_image_size").and_return(17)
          @item.preview_image.size.should == 17
        end

        it "should use the magic attribute for name if there is one, and not the job object" do
          @item.preview_image.send(:job).should_not_receive(:name)
          @item.should_receive("preview_image_name").and_return('jeffrey.bungle')
          @item.preview_image.name.should == 'jeffrey.bungle'
        end

        it "should delegate 'size' to the job object if there is no magic attribute for it" do
          @item.other_image = 'blahdata'
          @item.other_image.send(:job).should_receive(:size).and_return 54
          @item.other_image.size.should == 54
        end

      end

      it "should not raise an error if a non-existent method is called" do
        # Just checking method missing works ok
        lambda{
          @item.preview_image.eggbert
        }.should raise_error(NoMethodError)
      end
    end
    
    describe "job shortcuts" do
      before(:each) do
        @app.job :bacon do
          process :breakfast
        end
        @item = Item.new :preview_image => 'gurg'
      end
      it "should add job shortcuts for that app" do
        job = @item.preview_image.bacon
        job.steps.first.should be_a(Dragonfly::Job::Process)
      end
    end

    describe "setting things on the attachment" do

      before(:each) do
        @item = Item.new
      end

      describe "name" do
        before(:each) do
          @item.preview_image = "Hello"
          @item.preview_image.name = 'hello.there'
        end
        it "should allow for setting the name" do
          @item.preview_image.name.should == 'hello.there'
        end
        it "should update the magic attribute" do
          @item.preview_image_name.should == 'hello.there'
        end
        it "should return the name" do
          (@item.preview_image.name = 'no.silly').should == 'no.silly'
        end
        it "should update the ext too" do
          @item.preview_image.ext.should == 'there'
        end
      end

      describe "meta" do
        before(:each) do
          @item.preview_image = "Hello all"
          @item.preview_image.meta = {:slime => 'balls'}
        end
        it "should allow for setting the meta" do
          @item.preview_image.meta.should == {:slime => 'balls'}
        end
        it "should allow for updating the meta" do
          @item.preview_image.meta[:numb] = 'nuts'
          @item.preview_image.meta.should == {:slime => 'balls', :numb => 'nuts'}
        end
        it "should return the meta" do
          (@item.preview_image.meta = {:doogs => 'boogs'}).should == {:doogs => 'boogs'}
        end
        it "should save it correctly" do
          @item.save!
          item = Item.find(@item.id)
          item.preview_image.meta.should include_hash(:slime => 'balls')
        end
        it "should include meta info about the model" do
          @item.save!
          item = Item.find(@item.id)
          item.preview_image.meta.should include_hash(:model_class => 'Item', :model_attachment => :preview_image)  
        end
      end

    end

  end

  describe "inheritance" do

    before(:all) do
      @app = test_app
      @app2 = test_app
      @app.define_macro(MyModel, :image_accessor)
      @app2.define_macro(MyModel, :egg_accessor)
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
    it "should return the correct attachment classes for the base class" do
      @base_class.dragonfly_attachment_classes.should match_attachment_classes([[Car, :image, @app]])
    end
    it "should return the correct attachment classes for the subclass" do
      @subclass.dragonfly_attachment_classes.should match_attachment_classes([[ReliantRobin, :image, @app], [ReliantRobin, :reliant_image, @app]])
    end
    it "should return the correct attachment classes for the subclass with module" do
      @subclass_with_module.dragonfly_attachment_classes.should match_attachment_classes([[ReliantRobinWithModule, :image, @app], [ReliantRobinWithModule, :reliant_image, @app]])
    end
    it "should return the correct attachment classes for a class from a different hierarchy" do
      @unrelated_class.dragonfly_attachment_classes.should match_attachment_classes([[Photo, :image, @app2]])
    end
  end

  describe "setting the url" do
    before(:each) do
      set_up_item_class
      @item = Item.new
      stub_request(:get, "http://some.url/yo.png").to_return(:body => "aaaaayo")
    end

    it "should allow setting the url" do
      @item.preview_image_url = 'http://some.url/yo.png'
      @item.preview_image.data.should == 'aaaaayo'
    end
    it "should return nil always for the reader" do
      @item.preview_image_url = 'http://some.url/yo.png'
      @item.preview_image_url.should be_nil
    end
    it "should have set the name" do
      @item.preview_image_url = 'http://some.url/yo.png'
      @item.preview_image_name.should == 'yo.png'
      @item.preview_image.meta[:name].should == 'yo.png'
    end
    [nil, ""].each do |value|
      it "should do nothing if set with #{value.inspect}" do
        @item.preview_image_url = value
        @item.preview_image.should be_nil
      end
    end
  end

  describe "removing the accessor with e.g. a form" do
    before(:each) do
      set_up_item_class
      @item = Item.new
      @item.preview_image = "something"
    end
    
    [
      1,
      "1",
      true,
      "true",
      "blahblah"
    ].each do |value|
      it "should remove the accessor if passed #{value.inspect}" do
        @item.remove_preview_image = value
        @item.preview_image.should be_nil
      end

      it "should return true when called if set with #{value.inspect}" do
        @item.remove_preview_image = value
        @item.remove_preview_image.should be_true
      end
    end

    [
      0,
      "0",
      false,
      "false",
      "",
      nil
    ].each do |value|
      it "should not remove the accessor if passed #{value.inspect}" do
        @item.remove_preview_image = value
        @item.preview_image.should_not be_nil
      end

      it "should return false when called if set with #{value.inspect}" do
        @item.remove_preview_image = value
        @item.remove_preview_image.should be_false
      end
    end
    
    it "should return false by default for the getter" do
      @item.remove_preview_image.should be_false
    end
    
  end
  
  describe "callbacks" do

    describe "after_assign" do
      
      before(:each) do
        @app = test_app
        @app.define_macro(MyModel, :image_accessor)
      end

      describe "as a block" do
        
        def set_after_assign(*args, &block)
          Item.class_eval do
            image_accessor :preview_image do
              after_assign(*args, &block)
            end
          end
        end

        it "should call it after assign" do
          x = nil
          set_after_assign{ x = 3 }
          Item.new.preview_image = "hello"
          x.should == 3
        end

        it "should not call it after unassign" do
          x = nil
          set_after_assign{ x = 3 }
          Item.new.preview_image = nil
          x.should be_nil
        end
        
        it "should yield the attachment" do
          x = nil
          set_after_assign{|a| x = a.data }
          Item.new.preview_image = "discussion"
          x.should == "discussion"
        end
        
        it "should evaluate in the model context" do
          x = nil
          set_after_assign{ x = title.upcase }
          item = Item.new
          item.title = "big"
          item.preview_image = "jobs"
          x.should == "BIG"
        end
        
        it "should allow passing a symbol for calling a model method" do
          set_after_assign :set_title
          item = Item.new
          def item.set_title; self.title = 'duggen'; end
          item.preview_image = "jobs"
          item.title.should == "duggen"
        end

        it "should allow passing multiple symbols" do
          set_after_assign :set_title, :upcase_title
          item = Item.new
          def item.set_title; self.title = 'doobie'; end
          def item.upcase_title; self.title.upcase!; end
          item.preview_image = "jobs"
          item.title.should == "DOOBIE"
        end
        
        it "should not re-trigger callbacks (causing an infinite loop)" do
          set_after_assign{|a| self.preview_image = 'dogman' }
          item = Item.new
          item.preview_image = "hello"
        end

      end
    
    end
    
    describe "after_unassign" do
      before(:each) do
        @app = test_app
        @app.define_macro(MyModel, :image_accessor)
        Item.class_eval do
          image_accessor :preview_image do
            after_unassign{ self.title = 'unassigned' }
          end
        end
        @item = Item.new :title => 'yo'
      end
      
      it "should not call it after assign" do
        @item.preview_image = 'suggs'
        @item.title.should == 'yo'
      end
      
      it "should call it after unassign" do
        @item.preview_image = nil
        @item.title.should == 'unassigned'
      end
    end
    
    describe "copy_to" do
      before(:each) do
        @app = test_app
        @app.define_macro(MyModel, :image_accessor)
        @app.processor.add(:append) do |temp_object, string|
          temp_object.data + string
        end
        Item.class_eval do
          image_accessor :preview_image do
            copy_to(:other_image){|a| a.process(:append, title) }
            copy_to(:yet_another_image)
          end
          image_accessor :other_image
          image_accessor :yet_another_image
        end
        @item = Item.new :title => 'yo'
      end
      
      it "should copy to the other image when assigned" do
        @item.preview_image = 'hello bear'
        @item.other_image.data.should == 'hello bearyo'
      end

      it "should remove the other image when unassigned" do
        @item.preview_image = 'hello bear'
        @item.preview_image = nil
        @item.other_image.should be_nil
      end
      
      it "should allow simply copying over without args" do
        @item.preview_image = 'hello bear'
        @item.yet_another_image.data.should == 'hello bear'
      end
      
    end
    
  end

  describe "storage_opts" do
    
    def set_storage_opts(*args, &block)
      Item.class_eval do
        image_accessor :preview_image do
          storage_opts(*args, &block)
        end
      end
    end
    
    before(:each) do
      @app = test_app
      @app.define_macro(MyModel, :image_accessor)
    end
    
    it "should send the specified options to the datastore on store" do
      set_storage_opts :egg => 'head'
      item = Item.new :preview_image => 'hello'
      @app.datastore.should_receive(:store).with(anything, hash_including(:egg => 'head'))
      item.save!
    end
    
    it "should allow putting in a proc" do
      set_storage_opts{ {:egg => 'numb'} }
      item = Item.new :preview_image => 'hello'
      @app.datastore.should_receive(:store).with(anything, hash_including(:egg => 'numb'))
      item.save!
    end

    it "should yield the attachment and exec in model context" do
      set_storage_opts{|a| {:egg => (a.data + title)} }
      item = Item.new :title => 'lump', :preview_image => 'hello'
      @app.datastore.should_receive(:store).with(anything, hash_including(:egg => 'hellolump'))
      item.save!
    end

    it "should allow giving it a method symbol" do
      set_storage_opts :special_ops
      item = Item.new :preview_image => 'hello'
      def item.special_ops; {:a => 1}; end
      @app.datastore.should_receive(:store).with(anything, hash_including(:a => 1))
      item.save!
    end
    
    it "should allow setting more than once" do
      Item.class_eval do
        image_accessor :preview_image do
          storage_opts{{ :a => title, :b => 'dumple' }}
          storage_opts{{ :b => title.upcase, :c => 'digby' }}
        end
      end
      item = Item.new :title => 'lump', :preview_image => 'hello'
      @app.datastore.should_receive(:store).with(anything, hash_including(
        :a => 'lump', :b => 'LUMP', :c => 'digby'
      ))
      item.save!
    end
  end

  describe "storage_path, etc." do
   
    def set_storage_path(path=nil, &block)
      Item.class_eval do
        image_accessor :preview_image do
          storage_path(path, &block)
        end
        def monkey
          "mr/#{title}/monkey"
        end
      end
    end

    before(:each) do
      @app = test_app
      @app.define_macro(MyModel, :image_accessor)
    end

    it "should allow setting as a string" do
      set_storage_path 'always/the/same'
      item = Item.new :preview_image => 'bilbo'
      @app.datastore.should_receive(:store).with(anything, hash_including(
        :path => 'always/the/same'
      ))
      item.save!
    end

    it "should allow setting as a symbol" do
      set_storage_path :monkey
      item = Item.new :title => 'billy'
      item.preview_image = 'bilbo'
      @app.datastore.should_receive(:store).with(anything, hash_including(
        :path => 'mr/billy/monkey'
      ))
      item.save!
    end
  
    it "should allow setting as a block" do
      set_storage_path{|a| "#{a.data}/megs/#{title}" }
      item = Item.new :title => 'billy'
      item.preview_image = 'bilbo'
      @app.datastore.should_receive(:store).with(anything, hash_including(
        :path => 'bilbo/megs/billy'
      ))
      item.save!
    end

    it "should work for other storage_xxx declarations" do
      Item.class_eval do
        image_accessor :preview_image do
          storage_eggs 23
        end
      end
      item = Item.new :preview_image => 'bilbo'
      @app.datastore.should_receive(:store).with(anything, hash_including(
        :eggs => 23
      ))
      item.save!
    end
  end
  
  describe "unknown config method" do
    it "should raise an error" do
      lambda{
        Item.class_eval do
          image_accessor :preview_image do
            what :now?
          end
        end
      }.should raise_error(NoMethodError)
    end
  end
  
  describe "changed?" do
    before(:each) do
      set_up_item_class
      @item = Item.new
    end
    
    it "should be changed when assigned" do
      @item.preview_image = 'ggg'
      @item.preview_image.should be_changed
    end
    
    it "should not be changed when saved" do
      @item.preview_image = 'ggg'
      @item.save!
      @item.preview_image.should_not be_changed
    end

    it "should not be changed when reloaded" do
      @item.preview_image = 'ggg'
      @item.save!
      item = Item.find(@item.id)
      item.preview_image.should_not be_changed
    end
  end
  
  describe "retain and pending" do
    before(:each) do
      set_up_item_class(@app=test_app)
      @app.analyser.add :some_analyser_method do |temp_object|
        temp_object.data.upcase
      end
      @item = Item.new
    end

    it "should return nil if there are no changes" do
      @item.retained_preview_image.should be_nil
    end

    it "should return nil if assigned but not saved" do
      @item.preview_image = 'hello'
      @item.retained_preview_image.should be_nil
    end
    
    it "should return nil if assigned and saved" do
      @item.preview_image = 'hello'
      @item.save!
      @item.retained_preview_image.should be_nil
    end
    
    it "should return the saved stuff if assigned and retained" do
      @item.preview_image = 'hello'
      @item.preview_image.name = 'dog.biscuit'
      @app.datastore.should_receive(:store).with do |temp_object, opts|
        temp_object.data.should == 'hello'
        temp_object.meta.should == {
          :name => "dog.biscuit",
          :some_analyser_method => "HELLO",
          :size => 5,
          :model_class => "Item",
          :model_attachment => :preview_image
        }
      end.and_return('new/uid')
      @item.preview_image.retain!
      Dragonfly::Serializer.marshal_decode(@item.retained_preview_image).should == {
        :uid => 'new/uid',
        :some_analyser_method => 'HELLO',
        :size => 5,
        :name => 'dog.biscuit'
      }
    end
    
    it "should return nil if assigned, retained and saved" do
      @item.preview_image = 'hello'
      @item.preview_image.retain!
      @item.save!
      @item.retained_preview_image.should be_nil
    end

    it "should return nil if assigned, saved and retained" do
      @item.preview_image = 'hello'
      @item.save!
      @item.preview_image.retain!
      @item.retained_preview_image.should be_nil
    end

    it "should return nil if no changes have been made" do
      @item.preview_image = 'hello'
      @item.save!
      item = Item.find(@item.id)
      item.preview_image.retain!
      item.retained_preview_image.should be_nil
    end
  end
  
  describe "assigning from a pending state" do
    before(:each) do
      set_up_item_class(@app=test_app)
      @app.analyser.add :some_analyser_method do |temp_object|
        temp_object.data.upcase
      end
      @pending_string = Dragonfly::Serializer.marshal_encode(
        :uid => 'new/uid',
        :some_analyser_method => 'HELLO',
        :size => 5,
        :name => 'dog.biscuit'
      )
      @item = Item.new
    end

    it "should be retained" do
      @item.dragonfly_attachments[:preview_image].should_receive(:retain!)
      @item.retained_preview_image = @pending_string
    end
    
    it "should update the attributes" do
      @item.retained_preview_image = @pending_string
      @item.preview_image_uid.should == 'new/uid'
      @item.preview_image_some_analyser_method.should == 'HELLO'
      @item.preview_image_size.should == 5
      @item.preview_image_name.should == 'dog.biscuit'
    end
    
    it "should be a normal fetch job" do
      @item.retained_preview_image = @pending_string
      @app.datastore.should_receive(:retrieve).with('new/uid').and_return(Dragonfly::TempObject.new('retrieved yo'))
      @item.preview_image.data.should == 'retrieved yo'
    end

    it "should give the correct url" do
      @item.retained_preview_image = @pending_string
      @item.preview_image.url.should =~ %r{^/\w+/dog.biscuit$}
    end
    
    it "should raise an error if the pending string contains a non-magic attr method" do
      pending_string = Dragonfly::Serializer.marshal_encode(
        :uid => 'new/uid',
        :some_analyser_method => 'HELLO',
        :size => 5,
        :name => 'dog.biscuit',
        :something => 'else'
      )
      item = @item
      lambda{
        item.retained_preview_image = pending_string
      }.should raise_error(Dragonfly::ActiveModelExtensions::Attachment::BadAssignmentKey)
    end
    
    [nil, "", "asdfsad"].each do |value|
      it "should do nothing if assigned with #{value}" do
        @item.retained_preview_image = value
        @item.preview_image_uid.should be_nil
      end
    end
    
    it "should return the pending string again" do
      @item.retained_preview_image = @pending_string
      Dragonfly::Serializer.marshal_decode(@item.retained_preview_image).should ==
        Dragonfly::Serializer.marshal_decode(@pending_string)
    end
    
    it "should destroy the old one on save" do
      @item.preview_image = 'oldone'
      @app.datastore.should_receive(:store).with(a_temp_object_with_data('oldone'), anything).and_return('old/uid')
      @item.save!
      item = Item.find(@item.id)
      item.retained_preview_image = @pending_string
      @app.datastore.should_receive(:destroy).with('old/uid')
      item.save!
    end

    describe "combinations of assignment" do
      it "should destroy the previously retained one if something new is then assigned" do
        @item.retained_preview_image = @pending_string
        @app.datastore.should_receive(:destroy).with('new/uid')
        @item.preview_image = 'yet another new thing'
      end

      it "should destroy the previously retained one if something new is already assigned" do
        @item.preview_image = 'yet another new thing'
        @app.datastore.should_receive(:destroy).with('new/uid')
        @item.retained_preview_image = @pending_string
      end

      it "should destroy the previously retained one if nil is then assigned" do
        @item.retained_preview_image = @pending_string
        @app.datastore.should_receive(:destroy).with('new/uid')
        @item.preview_image = nil
      end

      it "should destroy the previously retained one if nil is already assigned" do
        @item.preview_image = nil
        @app.datastore.should_receive(:destroy).with('new/uid')
        @item.retained_preview_image = @pending_string
      end
      
      describe "automatically retaining (hack to test for existence of hidden form field)" do
        it "should automatically retain if set as an empty string then changed" do
          @item.retained_preview_image = ""
          @item.dragonfly_attachments[:preview_image].should_receive(:retain!)
          @item.preview_image = "hello"
        end

        it "should automatically retain if changed then set as an empty string" do
          @item.preview_image = "hello"
          @item.preview_image.should_receive(:retain!)
          @item.retained_preview_image = ""
        end

        it "should retain if retained_string then accessor is assigned" do
          @item.retained_preview_image = @pending_string
          @item.preview_image.should_receive(:retain!)
          @item.preview_image = 'yet another new thing'
        end

        it "should retain if accessor then retained_string is assigned" do
          @item.preview_image = 'yet another new thing'
          @item.preview_image.should_receive(:retain!)
          @item.retained_preview_image = @pending_string
        end
      end
    end

  end
  
  describe "format and mime type" do
    before(:each) do
      @app = test_app
      @app.analyser.add :mime_type do |temp_object|
        'some/type'
      end
      set_up_item_class(@app)
      @item = Item.new
      @content = "doggo"
      @content.stub!(:original_filename).and_return('egg.png')
    end
    it "should trust the file extension with format if configured to" do
      @item.preview_image = @content
      @item.preview_image.format.should == :png
    end
    it "should trust the file extension with mime_type if configured to" do
      @item.preview_image = @content
      @item.preview_image.mime_type.should == 'image/png'
    end
    it "should not trust the file extension with format if configured not to" do
      @app.trust_file_extensions = false
      @item.preview_image = @content
      @item.preview_image.format.should == nil
    end
    it "should not trust the file extension with mime_type if configured not to" do
      @app.trust_file_extensions = false
      @item.preview_image = @content
      @item.preview_image.mime_type.should == 'some/type'
    end
  end
  
  describe "inspect" do
    before(:each) do
      set_up_item_class
      @item = Item.new :preview_image => 'blug'
      @item.save!
    end
    it "should be awesome" do
      @item.preview_image.inspect.should =~ %r{^<Dragonfly Attachment uid="[^"]+", app=:test[_\w]*>$}
    end
  end
  
end
