require 'active_model'
require 'dragonfly/model/validations'

# Generic activemodel model
class MyModel

  extend Dragonfly::Model

  # Callbacks
  extend ActiveModel::Callbacks
  define_model_callbacks :save, :destroy

  include ActiveModel::Dirty

  class << self
    attr_writer :attribute_names
    def attribute_names
      @attribute_names ||= (superclass.attribute_names if superclass.respond_to?(:attribute_names))
    end

    attr_accessor :name

    def create!(attrs={})
      new(attrs).save!
    end

    def find(id)
      new(instances[id])
    end

    def instances
      @instances ||= {}
    end
  end

  def initialize(attrs={})
    attrs.each do |key, value|
      send("#{key}=", value)
    end
  end

  attr_accessor :id

  def to_hash
    self.class.attribute_names.inject({}) do |hash, attr|
      hash[attr] = send(attr)
      hash
    end
  end

  def save
    run_save_callbacks {
      self.id ||= rand(1000)
      self.class.instances[id] = self.to_hash
    }
  end
  def save!
    save
    self
  end

  def destroy
    run_destroy_callbacks {}
  end

  private

  def run_save_callbacks(&block)
    if respond_to?(:run_callbacks) # Rails 4
      run_callbacks :save, &block
    else
      _run_save_callbacks(&block)
    end
  end

  def run_destroy_callbacks(&block)
    if respond_to?(:run_callbacks) # Rails 4
      run_callbacks :destroy, &block
    else
      _run_destroy_callbacks(&block)
    end
  end
end

module ModelHelpers
  def new_model_class(name="TestModel", *attribute_names, &block)
    klass = Class.new(MyModel) do
      self.name = name
      include ActiveModel::Validations # Doing this here because it needs 'name' to be set
      self.attribute_names = attribute_names
      define_attribute_methods attribute_names
      attr_accessor *attribute_names
    end
    klass.class_eval(&block) if block
    klass
  end
end
