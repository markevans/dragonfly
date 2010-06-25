# Seems to blow up on Rails 3 without this
begin
  require 'active_support/all'
rescue LoadError => e
  puts "Couldn't load activesupport: #{e}"
end

class MigrationForTest < ActiveRecord::Migration
  
  def self.up
    create_table :items, :force => true do |t|
      t.string  :title
      t.string  :preview_image_uid
      t.string  :preview_image_some_analyser_method
      t.integer :preview_image_size
      t.string  :preview_image_name
      t.string  :preview_image_ext
      t.string  :preview_image_blah_blah
      t.string  :other_image_uid
      t.string  :yet_another_image_uid
      t.string  :otra_imagen_uid
      t.string  :trailer_video_uid
      t.timestamps
    end
    
    create_table :cars do |t|
      t.string :image_uid
      t.string :reliant_image_uid
      t.string :type
    end

    create_table :photos do |t|
      t.string :image_uid
    end

  end

  def self.down
    drop_table :items
  end

end
