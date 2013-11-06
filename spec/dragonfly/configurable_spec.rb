require 'spec_helper'

describe Dragonfly::Configurable do

  describe "Configurer" do

    let (:configurer) { Dragonfly::Configurable::Configurer.new do
      def colour(colour)
        obj.colour = colour
      end
    end }

    let (:obj) { Object.new }

    it "allows configuring" do
      obj.should_receive(:colour=).with('red')
      configurer.configure(obj) do
        colour 'red'
      end
    end

    it "doesn't allow non-existent methods" do
      expect{
        configurer.configure(obj) do
          color 'red'
        end
      }.to raise_error(NoMethodError)
    end

    it "doesn't call non-existent methods on the object" do
      obj.should_not_receive(:color=)
      begin
        configurer.configure(obj) do
          color 'red'
        end
      rescue NoMethodError
      end
    end

    it "provides a 'writer' shortcut" do
      configurer = Dragonfly::Configurable::Configurer.new do
        writer :colour, :size
      end
      obj.should_receive(:colour=).with('blue')
      obj.should_receive(:size=).with('big')
      configurer.configure(obj) do
        colour 'blue'
        size 'big'
      end
    end

    it "allows using the writer on another object" do
      configurer = Dragonfly::Configurable::Configurer.new do
        writer :colour, :for => :egg
      end
      egg = double('egg')
      obj.should_receive(:egg).and_return(egg)
      egg.should_receive(:colour=).with('pink')
      configurer.configure(obj) do
        colour 'pink'
      end
    end

    it "provides a 'meth' shortcut" do
      configurer = Dragonfly::Configurable::Configurer.new do
        meth :jobby, :nobby
      end
      obj.should_receive(:jobby).with('beans', :make => 5)
      obj.should_receive(:nobby).with(['nuts'])
      configurer.configure(obj) do
        jobby 'beans', :make => 5
        nobby ['nuts']
      end
    end

    it "allows using 'meth' on another object" do
      configurer = Dragonfly::Configurable::Configurer.new do
        meth :jobby, :for => :egg
      end
      egg = double('egg')
      obj.should_receive(:egg).and_return(egg)
      egg.should_receive(:jobby).with('beans', :make => 5)
      configurer.configure(obj) do
        jobby 'beans', :make => 5
      end
    end
  end

  describe "plugins" do

    let (:configurer) { Dragonfly::Configurable::Configurer.new{} }
    let (:obj) { Object.new }

    it "provides 'plugin' for using plugins" do
      pluggy = double('plugin')
      pluggy.should_receive(:call).with(obj, :a, 'few' => ['args'])
      configurer.configure(obj) do
        plugin pluggy, :a, 'few' => ['args']
      end
    end

    it "allows using 'plugin' with symbols" do
      pluggy = double('plugin')
      pluggy.should_receive(:call).with(obj, :a, 'few' => ['args'])
      configurer.register_plugin(:pluggy){ pluggy }
      configurer.configure(obj) do
        plugin :pluggy, :a, 'few' => ['args']
      end
    end

    it "adds the plugin to the object's 'plugins' if it responds to it when using symbols" do
      def obj.plugins; @plugins ||= {}; end
      pluggy = proc{}
      configurer.register_plugin(:pluggy){ pluggy }
      configurer.configure(obj) do
        plugin :pluggy
      end
      obj.plugins[:pluggy].should == pluggy
    end

    it "raises an error when a wrong symbol is used" do
      expect{
        configurer.configure(obj) do
          plugin :pluggy, :a, 'few' => ['args']
        end
      }.to raise_error(Dragonfly::Configurable::UnregisteredPlugin)
    end

  end

  describe "extending with Configurable" do

    let (:car_class) { Class.new do
      extend Dragonfly::Configurable
      attr_accessor :colour
    end }

    it "adds the set_up_config method to the class" do
      car_class.set_up_config do
        writer :colour
      end
    end

    it "adds the configure method to the instance" do
      car_class.set_up_config do
        writer :colour
      end
      car = car_class.new
      car.should_receive(:colour=).with('mauve')
      car.configure do
        colour 'mauve'
      end
    end

    it "adds the plugins method to the instance" do
      car_class.set_up_config do
        writer :colour
      end
      car = car_class.new
      car.plugins.should == {}
    end

    it "doesn't allow configuring if the class hasn't been set up" do
      car = car_class.new
      expect{
        car.configure{}
      }.to raise_error(NoMethodError)
    end

  end

  describe "nested configures" do

    before(:each) do
      @car_class = Class.new do
        extend Dragonfly::Configurable
        def initialize
          @numbers = []
        end
        attr_accessor :numbers
      end
      @car_class.set_up_config do
        def add(number)
          obj.numbers << number
        end
      end
    end

    it "should still work (as some plugins will configure inside a configure)" do
      car = @car_class.new
      car.configure do
        add 1
        car.configure do
          add 2
        end
        add 3
      end
      car.numbers.should == [1,2,3]
    end
  end

end

