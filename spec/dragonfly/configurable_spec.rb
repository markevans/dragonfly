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

    it "provides 'use' for using plugins" do
      plugin = mock('plugin')
      plugin.should_receive(:call).with(obj, :a, 'few' => ['args'])
      configurer.configure(obj) do
        use plugin, :a, 'few' => ['args']
      end
    end

  end

  describe "extending with Configurable" do
    
    let (:car_class) { Class.new do
      extend Dragonfly::Configurable
      attr_accessor :colour
    end }
    
    it "adds the setup_config method to the class" do
      car_class.setup_config do
        writer :colour
      end
    end
    
    it "adds the configure method to the instance" do
      car_class.setup_config do
        writer :colour
      end
      car = car_class.new
      car.should_receive(:colour=).with('mauve')
      car.configure do
        colour 'mauve'
      end
    end
    
    it "doesn't allow configuring if the class hasn't been set up" do
      car = car_class.new
      expect{
        car.configure{}
      }.to raise_error(NoMethodError)
    end
  end

end
