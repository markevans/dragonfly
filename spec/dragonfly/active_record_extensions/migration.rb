class MigrationForTest < ActiveRecord::Migration
  
  def self.up
    create_table :items, :force => true do |t|
      t.string  :title
      t.string  :preview_image_uid
      t.string  :trailer_video_uid
      t.timestamps
    end
  end

  def self.down
    drop_table :items
  end

end
