class MigrationForTest < ActiveRecord::Migration
  
  def self.up
    create_table :items, :force => true do |t|
      t.string  :title
      t.integer :preview_image_uid
      t.timestamps
    end
  end

  def self.down
    drop_table :items
  end

end
