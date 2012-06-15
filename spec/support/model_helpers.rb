require 'active_model'

# Generic activemodel model
class MyModel

  # Callbacks
  extend ActiveModel::Callbacks
  define_model_callbacks :save, :destroy

  include ActiveModel::Validations
  include ActiveModel::Dirty

  class << self
    attr_writer :attribute_names
    def attribute_names
      @attribute_names ||= (superclass.attribute_names if superclass.respond_to?(:attribute_names))
    end
    
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
    _run_save_callbacks {
      self.id ||= rand(1000)
      self.class.instances[id] = self.to_hash
    }
  end
  def save!
    save
    self
  end

  def destroy
    _run_destroy_callbacks {}
  end
end

module ModelHelpers
  def model_class(*attribute_names)
    Class.new(MyModel) do
      self.attribute_names = attribute_names
      define_attribute_methods attribute_names
      attr_accessor *attribute_names
    end
  end
  
  module_function :model_class
end

Item = ModelHelpers.model_class(
  :title,
  :preview_image_uid,
  :preview_image_some_analyser_method,
  :preview_image_size,
  :preview_image_name,
  :preview_image_blah_blah,
  :other_image_uid,
  :yet_another_image_uid,
  :otra_imagen_uid,
  :trailer_video_uid,
  :created_at,
  :updated_at
)

Car = ModelHelpers.model_class(
  :image_uid,
  :reliant_image_uid,
  :type
)

Photo = ModelHelpers.model_class(:image_uid)
