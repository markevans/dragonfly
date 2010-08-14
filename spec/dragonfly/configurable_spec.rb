require File.dirname(__FILE__) + '/../spec_helper'

describe Dragonfly::Configurable do

  before(:each) do
    class Car
      include Dragonfly::Configurable
      configurable_attr :colour
      configurable_attr :top_speed, 216
      def self.other_thing=(thing); end
    end
    @car = Car.new
  end

  describe "setup" do
    it "should provide attr_readers for configurable attributes" do
      @car.should respond_to(:colour)
    end

    it "should provide attr_writers for configurable attributes" do
      @car.colour = 'verde'
      @car.colour.should == 'verde'
    end

    it "should set default values for configurable attributes" do
      @car.top_speed.should == 216
    end

    it "should set the default as nil if not specified" do
      @car.colour.should be_nil
    end
    
    it "should allow specifying configurable attrs as strings" do
      class Bike
        include Dragonfly::Configurable
        configurable_attr 'colour', 'rude'
      end
      Bike.new.colour.should == 'rude'
    end
  end

  describe "configuring" do    
    it "should allow you to change values" do
      @car.configure do |c|
        c.colour = 'red'
      end
      @car.colour.should == 'red'
    end
    
    it "should not allow you to call other methods on the object via the configuration" do
      lambda{
        @car.configure do |c|
          c.other_thing = 5
        end
      }.should raise_error(Dragonfly::Configurable::BadConfigAttribute)
    end
    
    it "should return itself" do
      @car.configure{|c|}.should == @car
    end
  end
  
  describe "getting configuration" do
    it "should return the configuration as a hash" do
      @car.configuration.should == {:colour => nil, :top_speed => 216}
    end
    it "should not allow you to change the configuration via the hash" do
      @car.configuration[:top_speed] = 555
      @car.top_speed.should == 216
    end
  end
  
  describe "multiple objects" do
    it "should return the default configuration" do
      Car.default_configuration.should == {:colour => nil, :top_speed => 216}
    end
    it "should allow instances to be configured differently" do
      car1 = Car.new
      car1.configure{|c| c.colour = 'green'}
      car2 = Car.new
      car2.configure{|c| c.colour = 'yellow'}
      car1.configuration.should == {:colour => 'green', :top_speed => 216}
      car2.configuration.should == {:colour => 'yellow', :top_speed => 216}
    end
  end
  
  describe "lazy attributes" do
    before(:each) do
      cow = @cow = mock('cow')
      class Lazy; end
      Lazy.class_eval do
        include Dragonfly::Configurable
        configurable_attr(:sound){ cow.moo }
      end
      @lazy = Lazy.new
    end
    it "should not call the block if the configurable attribute is set to something else" do
      @cow.should_not_receive(:moo)
      @lazy.configure{|c| c.sound = 'baa' }
      @lazy.sound.should == 'baa'
    end
    it "should call the block if it's not been changed, once it's accessed" do
      @cow.should_receive(:moo).and_return('mooo!')
      @lazy.sound.should == 'mooo!'
    end
    it "should not call the block when accessed again" do
      @cow.should_receive(:moo).exactly(:once).and_return('mooo!')
      @lazy.sound.should == 'mooo!'
      @lazy.sound.should == 'mooo!'
    end
    it "should also call a block which has been set as part of the configuration" do
      @cow.should_receive(:fart).exactly(:once).and_return('paaarrp!')
      @lazy.configure{|c| c.sound = lambda{ @cow.fart }}
      @lazy.sound.should == 'paaarrp!'
      @lazy.sound.should == 'paaarrp!'
    end
  end
  
  describe "using in the singleton class" do
    it "should work" do
      class OneOff
        class << self
          include Dragonfly::Configurable
          configurable_attr :food, 'bread'
        end
      end
      OneOff.food.should == 'bread'
    end
  end
  
  describe "configuration method" do
    
    before(:each) do
      class ClassWithMethod
        include Dragonfly::Configurable
        def add_thing(thing)
          'poo'
        end
        def remove_thing(thing)
          'bum'
        end
        configuration_method :add_thing, :remove_thing
      end
      @thing = ClassWithMethod.new
    end
    
    it "should allow calling the method through 'configure'" do
      @thing.configure do |c|
        c.add_thing('duck')
        c.remove_thing('dog')
      end
    end
    
  end
  
  describe "nested configurable objects" do

    it "should allow configuring nested configurable objects" do

      class NestedThing
        include Dragonfly::Configurable
        configurable_attr :age, 29
      end

      class Car
        def nested_thing
          @nested_thing ||= NestedThing.new
        end
      end

      @car.configure do |c|
        c.nested_thing.configure do |nt|
          nt.age = 50
        end
      end

      @car.nested_thing.age.should == 50

    end

  end
  
  describe "configuring with a configurer" do
    before(:each) do
      @cool_configuration = Object.new
      def @cool_configuration.apply_configuration(car, colour=nil)
        car.configure do |c|
          c.colour = (colour || 'vermelho')
        end
      end
    end
    
    it "should allow configuration by a configurer" do
      @car.configure_with(@cool_configuration)
      @car.colour.should == 'vermelho'
      @car.top_speed.should == 216
    end
    
    it "should pass any args through to the configurer" do
      @car.configure_with(@cool_configuration, 'preto')
      @car.colour.should == 'preto'
    end
    
    it "should yield a block for any extra configuration" do
      @car.configure_with(@cool_configuration) do |c|
        c.colour = 'branco'
      end
      @car.colour.should == 'branco'
    end
    
    it "should return itself" do
      @car.configure_with(@cool_configuration).should == @car
    end
    
    it "should ask the object which object to configure with if a symbol is given" do
      @car.should_receive(:configurer_for).with(:cool).and_return(@cool_configuration)
      @car.configure_with(:cool)
      @car.colour.should == 'vermelho'
    end
  end
  
end
