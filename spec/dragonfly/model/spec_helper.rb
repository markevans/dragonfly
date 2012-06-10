require 'spec_helper'
require 'active_model'

# --------------------------------------------------------------- #
# MODELS
# --------------------------------------------------------------- #
class MyModel
  
  # Callbacks
  extend ActiveModel::Callbacks
  define_model_callbacks :save, :destroy
  
  include ActiveModel::Validations
  include ActiveModel::Dirty
  
  class << self
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
    self.class::ATTRIBUTES.inject({}) do |hash, attr|
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

class Item < MyModel
  
  ATTRIBUTES = [
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
  ]
  define_attribute_methods ATTRIBUTES
  attr_accessor *ATTRIBUTES
end

class Car < MyModel
  ATTRIBUTES = [
    :image_uid,
    :reliant_image_uid,
    :type
  ]
  define_attribute_methods ATTRIBUTES
  attr_accessor *ATTRIBUTES
end

class Photo < MyModel
  ATTRIBUTES = [:image_uid]
  define_attribute_methods ATTRIBUTES
  attr_accessor *ATTRIBUTES
end
