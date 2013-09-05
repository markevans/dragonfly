require 'spec_helper'
require 'dragonfly/model/validations'

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
      @item_class = new_model_class('Item',
        :preview_image_uid,
        :other_image_uid,
        :title
      ) do
        extend Dragonfly::Model::Validations

        dragonfly_accessor :preview_image
        dragonfly_accessor :other_image
      end
    end

    before(:each) do
      @item = @item_class.new(:preview_image => "1234567890")
    end

    it "should be valid if the property is correct" do
      @item_class.class_eval do
        validates_property :gungle, :of => :preview_image, :as => 'bungo'
      end
      @item.preview_image = "something"
      @item.preview_image.should_receive(:gungle).and_return('bungo')
      @item.should be_valid
    end

    it "should be valid if nil, if not validated on presence (even with validates_property)" do
      @item_class.class_eval do
        validates_property :size, :of => :preview_image, :as => 234
      end
      @item.preview_image = nil
      @item.should be_valid
    end

    it "should be invalid if the property is nil" do
      @item_class.class_eval do
        validates_property :gungle, :of => :preview_image, :in => ['bungo', 'jerry']
      end
      @item.preview_image = "something"
      @item.preview_image.should_receive(:gungle).and_return(nil)
      @item.should_not be_valid
      @item.errors[:preview_image].should == ["gungle is incorrect. It needs to be one of 'bungo', 'jerry'"]
    end

    it "should be invalid if the property is wrong" do
      @item_class.class_eval do
        validates_property :gungle, :of => :preview_image, :in => ['bungo', 'jerry']
      end
      @item.preview_image = "something"
      @item.preview_image.should_receive(:gungle).and_return('spangle')
      @item.should_not be_valid
      @item.errors[:preview_image].should == ["gungle is incorrect. It needs to be one of 'bungo', 'jerry', but was 'spangle'"]
    end

    it "is invalid if the property raises" do
      @item_class.class_eval do
        validates_property :gungle, :of => :preview_image, :as => 'bungo'
      end
      @item.preview_image = "something"
      @item.preview_image.should_receive(:gungle).and_raise(RuntimeError, "yikes!")
      @item.should_not be_valid
      @item.errors[:preview_image].should == ["gungle is incorrect. It needs to be 'bungo'"]
    end

    it "should work for a range" do
      @item_class.class_eval do
        validates_property :gungle, :of => :preview_image, :in => (0..2)
      end
      @item.preview_image = "something"
      @item.preview_image.should_receive(:gungle).and_return(3)
      @item.should_not be_valid
      @item.errors[:preview_image].should == ["gungle is incorrect. It needs to be between 0 and 2, but was '3'"]
    end

    it "should validate individually" do
      @item_class.class_eval do
        validates_property :size, :of => [:preview_image, :other_image], :as => 9
      end
      @item.preview_image = "something"
      @item.other_image = "something else"
      @item.should_not be_valid
      @item.errors[:preview_image].should == []
      @item.errors[:other_image].should == ["size is incorrect. It needs to be '9', but was '14'"]
    end

    it "should include standard extra options like 'if' on mime type validation" do
      @item_class.class_eval do
        validates_property :size, :of => :preview_image, :as => 4, :if => :its_friday
      end
      @item.preview_image = '13 characters'
      @item.should_receive(:its_friday).and_return(false)
      @item.should be_valid
    end

    it "should allow case sensitivity to be turned off when :as is specified" do
      @item_class.class_eval do
        validates_property :gungle, :of => :preview_image, :as => 'oKtHeN', :case_sensitive => false
      end
      @item.preview_image = "something"
      @item.preview_image.should_receive(:gungle).and_return('OKTHEN')
      @item.should be_valid
    end

    it "should allow case sensitivity to be turned off when :in is specified" do
      @item_class.class_eval do
        validates_property :gungle, :of => :preview_image, :in => ['oKtHeN'], :case_sensitive => false
      end
      @item.preview_image = "something"
      @item.preview_image.should_receive(:gungle).and_return('OKTHEN')
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
      @item_class.class_eval do
        validates_property :size, :of => :preview_image, :as => 4, :message => "errado, seu burro"
      end
      @item.preview_image = "something"
      @item.should_not be_valid
      @item.errors[:preview_image].should  == ["errado, seu burro"]
    end

    it "should allow for custom messages including access to the property name and expected/allowed values" do
      @item_class.class_eval do
        validates_property :size, :of => :preview_image, :as => 4,
          :message => proc{|actual, model| "Unlucky #{model.title}! Was #{actual}" }
      end
      @item.title = 'scubby'
      @item.preview_image = "too long"
      @item.should_not be_valid
      @item.errors[:preview_image].should  == ["Unlucky scubby! Was 8"]
    end

  end

end
