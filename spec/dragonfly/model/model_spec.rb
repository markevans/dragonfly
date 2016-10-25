require 'spec_helper'

# This spec is more of a functional spec for all of the model bits put together
describe "models" do

  before do
    Dragonfly.app.use_datastore(:memory)
  end

  describe "using the module" do
    it "adds 'dragonfly_accessor'" do
      klass = Class.new do
        extend Dragonfly::Model
        dragonfly_accessor :hello
      end
    end
  end

  describe "defining accessors" do

    before(:each) do
      @app1, @app2 = Dragonfly.app(:img), Dragonfly.app(:vid)
      app1, app2 = @app1, @app2
      @model_class = new_model_class do
        dragonfly_accessor :preview_image, :app => app1
        dragonfly_accessor :trailer_video, :app => app2
      end
      @classes = @model_class.dragonfly_attachment_classes
      @class1, @class2 = @classes
    end

    it "should return the attachment classes" do
      @class1.superclass.should == Dragonfly::Model::Attachment
      @class2.superclass.should == Dragonfly::Model::Attachment
    end

    it "should associate the correct app with each class" do
      @class1.app.should == @app1
      @class2.app.should == @app2
    end

    it "should associate the correct attribute with each class" do
      @class1.attribute.should == :preview_image
      @class2.attribute.should == :trailer_video
    end

    it "should associate the correct model class with each class" do
      @class1.model_class.should == @model_class
      @class2.model_class.should == @model_class
    end

    it "should allow passing the app name as the :app value" do
      klass = new_model_class do
        dragonfly_accessor :egg_nog, :app => :vid
      end
      klass.dragonfly_attachment_classes.first.app.should == @app2
    end

    it "should default the app to the default app" do
      klass = new_model_class do
        dragonfly_accessor :egg_nog
      end
      klass.dragonfly_attachment_classes.first.app.should == Dragonfly.app
    end
  end

  describe "correctly defined" do

    before(:each) do
      @app = test_app
      @item_class = new_model_class('Item', :preview_image_uid, :preview_image_size) do
        dragonfly_accessor :preview_image
      end
      @item = @item_class.new
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
        @app.datastore.should_not_receive(:write)
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

    describe "after a record with an empty uid is saved" do
      before(:each) do
        @item.preview_image_uid = ''
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
      it "should not try to read any data" do
        @app.datastore.should_not_receive(:read)
        @item.save!
      end
      it "should not try to destroy any data" do
        @app.datastore.should_not_receive(:destroy)
        @item.save!
      end
      it "should not try to store any data" do
        @app.datastore.should_not_receive(:write)
        @item.save!
      end
    end

    describe "when there has been some thing assigned but not saved" do
      before(:each) do
        @item.preview_image = "DATASTRING"
      end
      it "the reader should return an attachment" do
        @item.preview_image.should be_a(Dragonfly::Model::Attachment)
      end
      it "the uid should be nil" do
        @item.preview_image_uid.should be_nil
      end
      it "should store the image when saved" do
        @app.datastore.should_receive(:write).with(content_with_data("DATASTRING"), hash_including)
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
        it "should not try to read any data" do
          @app.datastore.should_not_receive(:read)
          @item.save!
        end
        it "should not try to destroy any data" do
          @app.datastore.should_not_receive(:destroy)
          @item.save!
        end
        it "should not try to store any data" do
          @app.datastore.should_not_receive(:write)
          @item.save!
        end
      end

    end

    describe "when something has been assigned and saved" do

      before(:each) do
        @item.preview_image = "DATASTRING"
        @app.datastore.should_receive(:write).with(content_with_data("DATASTRING"), hash_including).once.and_return('some_uid')
        @item.save!
      end

      it "should have the correct uid" do
        @item.preview_image_uid.should == 'some_uid'
      end
      it "should not try to store anything if saved again" do
        @app.datastore.should_not_receive(:write)
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
          @item = @item_class.find(@item.id)
        end
        it "should destroy the data on destroy" do
          @app.datastore.should_receive(:destroy).with(@item.preview_image_uid)
          @item.destroy
        end
      end

      describe "when something new is assigned" do
        before(:each) do
          @item.preview_image = "ANEWDATASTRING"
          @app.datastore.stub(:write).and_return('some_uid')
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
          @app.datastore.should_receive(:write).with(content_with_data("ANEWDATASTRING"), hash_including)
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
          @item.preview_image_uid_changed?.should be_truthy
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
          @item.preview_image_uid_changed?.should be_truthy
        end

      end

    end

    describe "other types of assignment" do
      before(:each) do
        @app.add_generator :egg do |content|
          content.update "Gungedin"
        end
        @app.add_processor :doogie do |content|
          content.update content.data.upcase
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
          @item_class.class_eval do
            attr_accessor :other_image_uid
            dragonfly_accessor :other_image
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
          @app.add_processor :double do |content|
            content.update content.data * 2
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
        it "should work repeatedly" do
          @item.preview_image.process!(:double).process!(:double)
          @item.preview_image.data.should == 'HELLOHELLOHELLOHELLO'
          @item.preview_image_size.should == 20
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

  describe "extra properties" do

    before(:each) do
      @app = test_app
      @app.add_analyser :some_analyser_method do |content|
        "abc" + content.data[0..0]
      end
      @app.add_analyser :number_of_As do |content|
        content.data.count('A')
      end

      @item_class = new_model_class('Item',
        :preview_image_uid,
        :preview_image_some_analyser_method,
        :preview_image_blah_blah,
        :preview_image_size,
        :preview_image_name,
        :other_image_uid
        ) do
        dragonfly_accessor :preview_image
        dragonfly_accessor :other_image
      end
      @item = @item_class.new
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
        data.stub(:original_filename).and_return('hello.png')
        @item.preview_image = data
        @item.preview_image_name.should == 'hello.png'
      end

      it "sets to nil if the analysis method blows up" do
        @app.add_analyser :some_analyser_method do |content|
          raise "oh dear"
        end
        @item.preview_image = '123'
        @item.preview_image_some_analyser_method.should be_nil
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
        @item.preview_image.respond_to?(:number_of_As).should be_truthy
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
          item = @item_class.create!(:preview_image => 'DATASTRING')
          @item = @item_class.find(item.id)
        end
        it "should load the content then delegate the method" do
          @item.preview_image.number_of_As.should == 2
        end
        it "should use the magic attribute if there is one, and not load the content" do
          @app.datastore.should_not_receive(:read)
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

    describe "setting things on the attachment" do

      before(:each) do
        @item = @item_class.new
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
        before :each do
          @item.preview_image = 'hello'
        end
        it "should include meta info about the model by default" do
          @item.preview_image.meta.should include_hash('model_class' => 'Item', 'model_attachment' => 'preview_image')
        end
        it "provides accessors" do
          @item.preview_image.meta = {'slime' => 'balls'}
          @item.preview_image.meta.should == {'slime' => 'balls'}
        end
        it "provides add_meta" do
          @item.preview_image.add_meta('sum' => 'ting').should == @item.preview_image
          @item.preview_image.meta['sum'].should == 'ting'
        end
      end

    end

  end

  describe "inheritance" do

    before(:all) do
      @app = test_app
      @app2 = test_app(:two)
      @car_class = new_model_class('Car', :image_uid, :reliant_image_uid) do
        dragonfly_accessor :image
      end
      @photo_class = new_model_class('Photo', :image_uid) do
        dragonfly_accessor :image, :app => :two
      end

      @base_class = @car_class
      class ReliantRobin < @car_class; dragonfly_accessor :reliant_image; end
      @subclass = ReliantRobin
      class ReliantRobinWithModule < @car_class
        include Module.new
        dragonfly_accessor :reliant_image
      end
      @subclass_with_module = ReliantRobinWithModule
      @unrelated_class = @photo_class
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
      @base_class.dragonfly_attachment_classes.should match_attachment_classes([[@car_class, :image, @app]])
    end
    it "should return the correct attachment classes for the subclass" do
      @subclass.dragonfly_attachment_classes.should match_attachment_classes([[ReliantRobin, :image, @app], [ReliantRobin, :reliant_image, @app]])
    end
    it "should return the correct attachment classes for the subclass with module" do
      @subclass_with_module.dragonfly_attachment_classes.should match_attachment_classes([[ReliantRobinWithModule, :image, @app], [ReliantRobinWithModule, :reliant_image, @app]])
    end
    it "should return the correct attachment classes for a class from a different hierarchy" do
      @unrelated_class.dragonfly_attachment_classes.should match_attachment_classes([[@photo_class, :image, @app2]])
    end
  end

  describe "setting the url" do
    before(:each) do
      @item_class = new_model_class('Item', :preview_image_uid, :preview_image_name) do
        dragonfly_accessor :preview_image
      end
      @item = @item_class.new
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
      @item.preview_image.meta['name'].should == 'yo.png'
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
      @item_class = new_model_class('Item', :preview_image_uid) do
        dragonfly_accessor :preview_image
      end
      @item = @item_class.new
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
        @item.remove_preview_image.should be_truthy
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
        @item.remove_preview_image.should be_falsey
      end
    end

    it "should return false by default for the getter" do
      @item.remove_preview_image.should be_falsey
    end

  end

  describe "callbacks" do

    describe "after_assign" do

      before(:each) do
        @app = test_app
        @item_class = new_model_class('Item', :preview_image_uid, :title)
      end

      describe "as a block" do

        def set_after_assign(*args, &block)
          @item_class.class_eval do
            dragonfly_accessor :preview_image do
              after_assign(*args, &block)
            end
          end
        end

        it "should call it after assign" do
          x = nil
          set_after_assign{ x = 3 }
          @item_class.new.preview_image = "hello"
          x.should == 3
        end

        it "should not call it after unassign" do
          x = nil
          set_after_assign{ x = 3 }
          @item_class.new.preview_image = nil
          x.should be_nil
        end

        it "should yield the attachment" do
          x = nil
          set_after_assign{|a| x = a.data }
          @item_class.new.preview_image = "discussion"
          x.should == "discussion"
        end

        it "should evaluate in the model context" do
          x = nil
          set_after_assign{ x = title.upcase }
          item = @item_class.new
          item.title = "big"
          item.preview_image = "jobs"
          x.should == "BIG"
        end

        it "should allow passing a symbol for calling a model method" do
          set_after_assign :set_title
          item = @item_class.new
          def item.set_title; self.title = 'duggen'; end
          item.preview_image = "jobs"
          item.title.should == "duggen"
        end

        it "should allow passing multiple symbols" do
          set_after_assign :set_title, :upcase_title
          item = @item_class.new
          def item.set_title; self.title = 'doobie'; end
          def item.upcase_title; self.title.upcase!; end
          item.preview_image = "jobs"
          item.title.should == "DOOBIE"
        end

        it "should not re-trigger callbacks (causing an infinite loop)" do
          set_after_assign{|a| self.preview_image = 'dogman' }
          item = @item_class.new
          item.preview_image = "hello"
        end

      end

    end

    describe "after_unassign" do
      before(:each) do
        @app = test_app
        @item_class = new_model_class('Item', :preview_image_uid, :title) do
          dragonfly_accessor :preview_image do
            after_unassign{ self.title = 'unassigned' }
          end
        end
        @item = @item_class.new :title => 'yo'
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
        @app.add_processor(:append) do |content, string|
          content.update(content.data + string)
        end
        @item_class = new_model_class('Item', :preview_image_uid, :other_image_uid, :yet_another_image_uid, :title) do
          dragonfly_accessor :preview_image do
            copy_to(:other_image){|a| a.process(:append, title) }
            copy_to(:yet_another_image)
          end
          dragonfly_accessor :other_image
          dragonfly_accessor :yet_another_image
        end
        @item = @item_class.new :title => 'yo'
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

  describe "storage_options" do

    def set_storage_options(*args, &block)
      @item_class.class_eval do
        dragonfly_accessor :preview_image do
          storage_options(*args, &block)
        end
      end
    end

    before(:each) do
      @app = test_app
      @item_class = new_model_class('Item', :preview_image_uid, :title)
    end

    it "should send the specified options to the datastore on store" do
      set_storage_options :egg => 'head'
      item = @item_class.new :preview_image => 'hello'
      @app.datastore.should_receive(:write).with(anything, hash_including(:egg => 'head'))
      item.save!
    end

    it "should allow putting in a proc" do
      set_storage_options{ {:egg => 'numb'} }
      item = @item_class.new :preview_image => 'hello'
      @app.datastore.should_receive(:write).with(anything, hash_including(:egg => 'numb'))
      item.save!
    end

    it "should yield the attachment and exec in model context" do
      set_storage_options{|a| {:egg => (a.data + title)} }
      item = @item_class.new :title => 'lump', :preview_image => 'hello'
      @app.datastore.should_receive(:write).with(anything, hash_including(:egg => 'hellolump'))
      item.save!
    end

    it "should allow giving it a method symbol" do
      set_storage_options :special_ops
      item = @item_class.new :preview_image => 'hello'
      def item.special_ops; {:a => 1}; end
      @app.datastore.should_receive(:write).with(anything, hash_including(:a => 1))
      item.save!
    end

    it 'should pass the attachment object if the method allows' do
      set_storage_options :special_ops
      item = @item_class.new :title => 'lump', :preview_image => 'hello'
      def item.special_ops(a); {:egg => (a.data + title)}; end
      @app.datastore.should_receive(:write).with(anything, hash_including(:egg => 'hellolump'))
      item.save!
    end

    it "should allow setting more than once" do
      @item_class.class_eval do
        dragonfly_accessor :preview_image do
          storage_options{{ :a => title, :b => 'dumple' }}
          storage_options{{ :b => title.upcase, :c => 'digby' }}
        end
      end
      item = @item_class.new :title => 'lump', :preview_image => 'hello'
      @app.datastore.should_receive(:write).with(anything, hash_including(
        :a => 'lump', :b => 'LUMP', :c => 'digby'
      ))
      item.save!
    end

    it "gives a deprecation warning for storage_xxx methods" do
      expect {
        @item_class.class_eval do
          dragonfly_accessor :preview_image do
            storage_egg :fried
          end
        end
      }.to raise_error(/deprecated/)
    end
  end

  describe "default" do
    before do
      @app = test_app
      @item_class = new_model_class('Item', :image_uid) do
        dragonfly_accessor :image do
          default SAMPLES_DIR.join('beach.jpg')
        end
      end
      @item = @item_class.new
    end

    it "gives a default image when not set" do
      @item.image.name.should == 'beach.jpg'
      @item.image.size.should == 25932
    end

    it "acts as normal otherwise" do
      @item.image = "asdf"
      @item.image.data.should == "asdf"
    end

    it "adds to the path whitelist" do
      path = SAMPLES_DIR.join('beach.jpg')
      @app.fetch_file_whitelist.should include File.expand_path(path)
    end
  end

  describe "unknown config method" do
    it "should raise an error" do
      item_class = new_model_class('Item', :preview_image_uid)
      lambda{
        item_class.class_eval do
          dragonfly_accessor :preview_image do
            what :now?
          end
        end
      }.should raise_error(NoMethodError)
    end
  end

  describe "xxx_changed?" do
    before(:each) do
      @item_class = new_model_class('Item', :preview_image_uid) do
        dragonfly_accessor :preview_image
      end
      @item = @item_class.new
    end

    it "should be changed when assigned" do
      expect( @item.preview_image_changed? ).to be_falsey
      @item.preview_image = 'ggg'
      expect( @item.preview_image_changed? ).to be_truthy
    end

    describe "after saving" do
      before do
        @item.preview_image = 'ggg'
        @item.save!
      end

      it "should not be changed" do
        expect( @item.preview_image_changed? ).to be_falsey
      end

      it "should be changed when set to nil" do
        @item.preview_image = nil
        expect( @item.preview_image_changed? ).to be_truthy
      end

      it "should be changed when changed" do
        @item.preview_image = "asdf"
        expect( @item.preview_image_changed? ).to be_truthy
      end

      it "should not be changed when reloaded" do
        item = @item_class.find(@item.id)
        expect( @item.preview_image_changed? ).to be_falsey
      end

    end
  end

  describe "retain and pending" do
    before(:each) do
      @app=test_app
      @app.add_analyser :some_analyser_method do |content|
        content.data.upcase
      end
      @item_class = new_model_class('Item',
        :preview_image_uid,
        :preview_image_some_analyser_method,
        :preview_image_size,
        :preview_image_name
        ) do
        dragonfly_accessor :preview_image
      end
      @item = @item_class.new
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
      @app.datastore.should_receive(:write).with(
        satisfy{|content| content.data == 'hello' },
        anything
      ).and_return('new/uid')
      @item.preview_image.retain!
      Dragonfly::Serializer.json_b64_decode(@item.retained_preview_image).should == {
        'uid' => 'new/uid',
        'some_analyser_method' => 'HELLO',
        'size' => 5,
        'name' => 'dog.biscuit'
      }
    end

    it "should rescue analysis errors" do
      @app.add_analyser(:some_analyser_method){ raise "oh no!" }
      @item.preview_image = 'hello'
      @item.preview_image.retain!
      attrs = Dragonfly::Serializer.json_b64_decode(@item.retained_preview_image)
      attrs['some_analyser_method'].should be_nil
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
      item = @item_class.find(@item.id)
      item.preview_image.retain!
      item.retained_preview_image.should be_nil
    end
  end

  describe "assigning from a pending state" do
    before(:each) do
      @app=test_app
      @app.add_analyser :some_analyser_method do |content|
        content.data.upcase
      end
      @uid = @app.store('retrieved yo')
      @pending_string = Dragonfly::Serializer.json_b64_encode(
        'uid' => @uid,
        'some_analyser_method' => 'HELLO',
        'size' => 5,
        'name' => 'dog.biscuit'
      )
      @item_class = new_model_class('Item',
        :preview_image_uid,
        :preview_image_size,
        :preview_image_some_analyser_method,
        :preview_image_name
        ) do
        dragonfly_accessor :preview_image
      end
      @item = @item_class.new
    end

    it "should be retained" do
      @item.dragonfly_attachments[:preview_image].should_receive(:retain!)
      @item.retained_preview_image = @pending_string
    end

    it "should update the attributes" do
      @item.retained_preview_image = @pending_string
      @item.preview_image_uid.should == @uid
      @item.preview_image_some_analyser_method.should == 'HELLO'
      @item.preview_image_size.should == 5
      @item.preview_image_name.should == 'dog.biscuit'
    end

    it "should be a normal fetch job" do
      @item.retained_preview_image = @pending_string
      @item.preview_image.data.should == 'retrieved yo'
    end

    it "should give the correct url" do
      @item.retained_preview_image = @pending_string
      @item.preview_image.url.should =~ %r{^/\w+/dog.biscuit}
    end

    it "should raise an error if the pending string contains a non-magic attr method" do
      pending_string = Dragonfly::Serializer.json_b64_encode(
        'uid' => @uid,
        'some_analyser_method' => 'HELLO',
        'size' => 5,
        'name' => 'dog.biscuit',
        'something' => 'else'
      )
      item = @item
      lambda{
        item.retained_preview_image = pending_string
      }.should raise_error(Dragonfly::Model::Attachment::BadAssignmentKey)
    end

    [
      nil,
      "",
      "asdfsad" # assigning with rubbish shouldn't break it
    ].each do |value|
      it "should do nothing if assigned with #{value}" do
        @item.retained_preview_image = value
        @item.preview_image_uid.should be_nil
      end
    end

    it "should return the pending string again" do
      @item.retained_preview_image = @pending_string
      Dragonfly::Serializer.json_b64_decode(@item.retained_preview_image).should ==
        Dragonfly::Serializer.json_b64_decode(@pending_string)
    end

    it "should destroy the old one on save" do
      @item.preview_image = 'oldone'
      @app.datastore.should_receive(:write).with(content_with_data('oldone'), anything).and_return('old/uid')
      @item.save!
      item = @item_class.find(@item.id)
      item.retained_preview_image = @pending_string
      @app.datastore.should_receive(:destroy).with('old/uid')
      item.save!
    end

    describe "combinations of assignment" do
      it "should destroy the previously retained one if something new is then assigned" do
        @item.retained_preview_image = @pending_string
        @app.datastore.should_receive(:destroy).with(@uid)
        @item.preview_image = 'yet another new thing'
      end

      it "should destroy the previously retained one if something new is already assigned" do
        @item.preview_image = 'yet another new thing'
        @app.datastore.should_receive(:destroy).with(@uid)
        @item.retained_preview_image = @pending_string
      end

      it "should destroy the previously retained one if nil is then assigned" do
        @item.retained_preview_image = @pending_string
        @app.datastore.should_receive(:destroy).with(@uid)
        @item.preview_image = nil
      end

      it "should destroy the previously retained one if nil is already assigned" do
        @item.preview_image = nil
        @app.datastore.should_receive(:destroy).with(@uid)
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

  describe "xxx_stored?" do
    before do
      item_class = new_model_class('Item', :photo_uid) do
        dragonfly_accessor :photo
      end
      @item = item_class.new
    end

    it "returns false if unassigned" do
      @item.photo_stored?.should be_falsey
    end

    it "returns false if assigned but not stored" do
      @item.photo = "Asdf"
      @item.photo_stored?.should be_falsey
    end

    it "returns true if stored" do
      @item.photo = "Asdf"
      @item.save!
      @item.photo_stored?.should be_truthy
    end
  end

  describe "misc properties" do
    before(:each) do
      @item_class = new_model_class('Item', :photo_uid) do
        dragonfly_accessor :photo
      end
      @item = @item_class.new :photo => 'blug'
    end

    it "returns the b64_data" do
      @item.photo.b64_data.should =~ /^data:/
    end

    it "returns the mime_type" do
      @item.photo.ext = 'txt'
      @item.photo.mime_type.should == 'text/plain'
    end
  end

  describe "inspect" do
    before(:each) do
      @item_class = new_model_class('Item', :preview_image_uid) do
        dragonfly_accessor :preview_image
      end
      @item = @item_class.new :preview_image => 'blug'
      @item.save!
    end
    it "should be awesome" do
      @item.preview_image.inspect.should =~ %r{^<Dragonfly Attachment uid="[^"]+", app=:default>$}
    end
  end

  describe 'overwriting instance methods' do
    let(:klass) do
      new_model_class('Item', :foo_uid) do
        dragonfly_accessor :foo

        def foo
          super
        end
      end
    end

    let(:item) { klass.new }

    it 'works as expected when calling super' do
      item.foo.should be_nil
      item.foo = 'DATASTRING'
      item.foo.should be_a(Dragonfly::Model::Attachment)
    end
  end
end
