require 'spec_helper'

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
    
    it "should allow setting to nil" do
      @car.top_speed = nil
      @car.top_speed.should be_nil
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
    it "should return the configuration when nothing is set" do
      @car.configuration.should == {}
    end
    it "should return the configuration when something is set" do
      @car.top_speed = 10
      @car.configuration.should == {:top_speed => 10}
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
      car1.configuration.should == {:colour => 'green'}
      car2.configuration.should == {:colour => 'yellow'}
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
    it "should not call an explicitly passed in proc" do
      @lazy.configure{|c| c.sound = lambda{ @cow.fart }}
      @lazy.sound.should be_a(Proc)
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

    before(:each) do
      class NestedThing
        include Dragonfly::Configurable
        configurable_attr :age, 29
        def some_method(val)
          @some_thing = val
        end
        configuration_method :some_method
        attr_reader :some_thing
      end

      class Car
        def nested_thing
          @nested_thing ||= NestedThing.new
        end
        nested_configurable :nested_thing
      end

      @car.configure do |c|
        c.nested_thing.configure do |nt|
          nt.age = 50
          nt.some_method('yo')
        end
      end
    end

    it "should allow configuring nested configurable accessors" do
      @car.nested_thing.age.should == 50
    end

    it "should allow configuring nested configurable normal methods" do
      @car.nested_thing.some_thing.should == 'yo'
    end
    
    it "should not allow configuring directly on the config object" do
      expect{
        @car.configure do |c|
          c.some_method('other')
        end
      }.to raise_error(Dragonfly::Configurable::BadConfigAttribute)
    end
  end
  
  describe "configuring with a saved config" do
    before(:each) do
      @cool_configuration = Object.new
      def @cool_configuration.apply_configuration(car, colour=nil)
        car.configure do |c|
          c.colour = (colour || 'vermelho')
        end
      end
    end
    
    it "should allow configuration by a saved config" do
      @car.configure_with(@cool_configuration)
      @car.colour.should == 'vermelho'
      @car.top_speed.should == 216
    end
    
    it "should pass any args through to the saved config" do
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
    
    describe "using a symbol to specify the config" do

      before(:all) do
        @rally_config = Object.new
        Car.register_configuration(:rally, @rally_config)
        @long_journey_config = Object.new
        Car.register_configuration(:long_journey){ @long_journey_config }
        Car.register_configuration(:some_library){ SomeLibrary }
      end

      it "should map the symbol to the correct configuration" do
        @rally_config.should_receive(:apply_configuration).with(@car)
        @car.configure_with(:rally)
      end

      it "should map the symbol to the correct configuration lazily" do
        @long_journey_config.should_receive(:apply_configuration).with(@car)
        @car.configure_with(:long_journey)
      end

      it "should throw an error if an unknown symbol is passed in" do
        lambda {
          @car.configure_with(:eggs)
        }.should raise_error(ArgumentError)
      end

      it "should only try to load the library when asked to" do
        lambda{
          @car.configure_with(:some_library)
        }.should raise_error(NameError, /uninitialized constant.*SomeLibrary/)
      end
    end
    
  end
  
  describe "falling back to another config" do
    before(:each) do
      class Garage
        include Dragonfly::Configurable
        configurable_attr :top_speed, 100
      end
      @garage = Garage.new
      @car.use_as_fallback_config(@garage)
    end
    
    describe "when nothing set" do
      it "should use its default" do
        @car.top_speed.should == 216
      end
      it "shouldn't affect the fallback config object" do
        @garage.top_speed.should == 100
      end
    end
    
    describe "if set" do
      before(:each) do
        @car.top_speed = 444
      end
      it "should work normally" do
        @car.top_speed.should == 444
      end
      it "shouldn't affect the fallback config object" do
        @garage.top_speed.should == 100
      end
    end
    
    describe "both set" do
      before(:each) do
        @car.top_speed = 444
        @garage.top_speed = 3000
      end
      it "should prefer its own setting" do
        @car.top_speed.should == 444
      end
      it "shouldn't affect the fallback config object" do
        @garage.top_speed.should == 3000
      end
    end
    
    describe "the fallback config is set" do
      before(:each) do
        @garage.top_speed = 3000
      end
      it "should use the fallback config" do
        @car.top_speed.should == 3000
      end
      it "shouldn't affect the fallback config object" do
        @garage.top_speed.should == 3000
      end
    end
    
    describe "falling back multiple levels" do
      before(:each) do
        @klass = Class.new
        @klass.class_eval do
          include Dragonfly::Configurable
          configurable_attr :veg, 'carrot'
        end
        @a = @klass.new
        @b = @klass.new
        @b.use_as_fallback_config(@a)
        @c = @klass.new
        @c.use_as_fallback_config(@b)
      end
      
      it "should be the default if nothing set" do
        @c.veg.should == 'carrot'
      end
      
      it "should fall all the way back to the top one if necessary" do
        @a.veg = 'turnip'
        @c.veg.should == 'turnip'
      end
      
      it "should prefer the closer one over the further away one" do
        @b.veg = 'tatty'
        @a.veg = 'turnip'
        @c.veg.should == 'tatty'
      end
      
      it "should work properly with nils" do
        @a.veg = nil
        @c.veg = 'broc'
        @a.veg.should be_nil
        @b.veg.should be_nil
        @c.veg.should == 'broc'
      end
    end
    
    describe "objects with different methods" do
      before(:each) do
        class Dad
          include Dragonfly::Configurable
        end
        @dad = Dad.new
        class Kid
          include Dragonfly::Configurable
          configurable_attr :lug, 'default-lug'
        end
        @kid = Kid.new
        @kid.use_as_fallback_config(@dad)
      end

      it "should not allow setting on the fallback obj directly" do
        lambda{
          @dad.lug = 'leg'
        }.should raise_error(NoMethodError)
      end

      it "should not have the fallback obj respond to the method" do
        @dad.should_not respond_to(:lug=)
      end

      it "should allow configuring through the fallback object even if it doesn't have that method" do
        @dad.configure do |c|
          c.lug = 'leg'
        end
        @kid.lug.should == 'leg'
      end
      
      it "should work when a grandchild config is added later" do
        class Grandkid
          include Dragonfly::Configurable
          configurable_attr :oogie, 'boogie'
        end
        grandkid = Grandkid.new
        grandkid.use_as_fallback_config(@kid)
        @dad.configure{|c| c.oogie = 'duggen' }
        grandkid.oogie.should == 'duggen'
      end

      it "should allow configuring twice through the fallback object" do
        @dad.configure{|c| c.lug = 'leg' }
        @dad.configure{|c| c.lug = 'blug' }
        @kid.lug.should == 'blug'
      end
    end
    
    describe "clashing with configurable modules" do
      before(:each) do
        @mod = mod = Module.new
        @mod.module_eval do
          include Dragonfly::Configurable
          configurable_attr :team, 'spurs'
        end
        @class = Class.new
        @class.class_eval do
          include mod
          include Dragonfly::Configurable
          configurable_attr :tree, 'elm'
        end
      end
      
      it "should not override the defaults from the module" do
        obj = @class.new
        obj.team.should == 'spurs'
      end
      
      it "should still use its own defaults" do
        obj = @class.new
        obj.tree.should == 'elm'
      end
      
      describe "when the configurable_attr is specified in a subclass that doesn't include Configurable" do
        before(:each) do
          @subclass = Class.new(@class)
          @subclass.class_eval do
            configurable_attr :car, 'mazda'
            configurable_attr :tree, 'oak'
          end
          @obj = @subclass.new
        end

        it "should still work with default values" do
          @obj.car.should == 'mazda'
        end

        it "should override the default from the parent" do
          @obj.tree.should == 'oak'
        end
      end

    end
    
  end

  describe "inheriting configurable_attrs from multiple places" do
    before(:each) do
      module A
        include Dragonfly::Configurable
        configurable_attr :a
      end
      module B
        include Dragonfly::Configurable
        configurable_attr :b
      end
      class K
        include Dragonfly::Configurable
        include A
        include B
        configurable_attr :c
      end
      class L < K
      end
    end
    
    it "should include configuration from all of its mixins" do
      l = L.new
      l.configure do |c|
        c.a = 'something'
        c.b = 'something'
        c.c = 'something'
      end
    end
  end
end
