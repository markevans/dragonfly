require 'spec_helper'

describe Dragonfly::Model::Validations do

  before(:each) do
    @app = test_app
  end

  describe "validates_presence_of" do
    before(:each) do
      @item_class = new_model_class('Item', :preview_image_uid) do
        dragonfly_accessor :preview_image
        validates_presence_of :preview_image
      end
    end

    it "should be valid if set" do
      @item_class.new(:preview_image => "1234567890").should be_valid
    end

    it "should be invalid if not set" do
      @item_class.new.should_not be_valid
    end
  end

  describe "validates_size_of" do
    before(:each) do
      @item_class = new_model_class('Item', :preview_image_uid) do
        dragonfly_accessor :preview_image
        validates_size_of :preview_image, :within => (6..10)
      end
    end

    it "should be valid if ok" do
      @item_class.new(:preview_image => "1234567890").should be_valid
    end

    it "should be invalid if too small" do
      @item_class.new(:preview_image => "12345").should_not be_valid
    end
  end

  describe "validates_property" do

    before(:each) do
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

      @item_class = new_model_class('Item', 
        :preview_image_uid,
        :other_image_uid,
        :yet_another_image_uid,
        :otra_imagen_uid,
        :title
      ) do
        extend Dragonfly::Model::Validations
        
        validates_property :mime_type, :of => :preview_image, :in => ['how/special', 'how/crazy'], :if => :its_friday
        validates_property :mime_type, :of => [:other_image, :yet_another_image], :as => 'how/special'
        validates_property :number_of_Gs, :of => :preview_image, :in => (0..2)
        validates_property :mime_type, :of => :otra_imagen, :in => ['que/pasa', 'illo/tio'], :message => "tipo de contenido incorrecto. Que chungo tio"

        dragonfly_accessor :preview_image
        dragonfly_accessor :other_image
        dragonfly_accessor :yet_another_image
        dragonfly_accessor :otra_imagen

        def its_friday
          true
        end
      end
    end

    before(:each) do
      @item = @item_class.new(:preview_image => "1234567890")
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
      @item_class.class_eval do
        validates_property :mime_type, :of => :preview_image, :as => 'WronG/TypE', :case_sensitive => false
      end
      @item.preview_image = "WRONG TYPE"
      @item.should be_valid
    end

    it "should allow case sensitivity to be turned off when :in is specified" do
      @item.should_receive(:its_friday).and_return(false)
      @item_class.class_eval do
        validates_property :mime_type, :of => :preview_image, :in => ['WronG/TypE'], :case_sensitive => false
      end
      @item.preview_image = "WRONG TYPE"
      @item.should be_valid
    end

    it "should require either :as or :in as an argument" do
      lambda{
        @item_class.class_eval do
          validates_property :mime_type, :of => :preview_image
        end
      }.should raise_error(ArgumentError)
    end

    it "should require :of as an argument" do
      lambda{
        @item_class.class_eval do
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
      @item_class.class_eval do
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
