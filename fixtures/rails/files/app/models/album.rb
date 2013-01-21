class Album < ActiveRecord::Base
  attr_accessible :name, :retained_cover_image, :cover_image
  validates_property :format, :of => :cover_image, :in => [:jpg, :png, :gif]
  validates_length_of :name, :in => 0..5
  image_accessor :cover_image
end