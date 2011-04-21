class Album < ActiveRecord::Base
  validates_property :format, :of => :cover_image, :in => [:jpg, :png, :gif]
  validates_length_of :name, :in => 0..5
  image_accessor :cover_image
end