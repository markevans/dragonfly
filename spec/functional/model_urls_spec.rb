require 'dragonfly/active_model_extensions/spec_helper'
require 'tempfile'

describe "model urls" do
  
  def new_tempfile(data='HELLO', filename='hello.txt')
    tempfile = Tempfile.new('test')
    tempfile.write(data)
    tempfile.rewind
    tempfile.stub!(:original_filename).and_return(filename)
    tempfile
  end
  
  before(:each) do
    @app = Dragonfly[:model_urls_test].configure do |c|
      c.url_format = '/media/:job/:basename.:format'
    end
    @app.define_macro(MyModel, :image_accessor)
    Item.class_eval do
      image_accessor :preview_image # has name etc.
      image_accessor :other_image # doesn't have magic stuff
    end
    @item = Item.new
  end
  
  it "should include the name in the url if it has the magic attribute" do
    @item.preview_image = new_tempfile
    @item.save!
    item = Item.find(@item.id)
    item.preview_image.url.should =~ %r{^/media/\w+/hello\.txt$}
  end
  
  it "should work without the name if the name magic attr doesn't exist" do
    @item.other_image = new_tempfile
    @item.save!
    item = Item.find(@item.id)
    item.other_image.url.should =~ %r{^/media/\w+$}
  end
  
  it "should include the name in the url even if it has no ext" do
    @item.preview_image = new_tempfile("hello", 'hello')
    @item.save!
    item = Item.find(@item.id)
    item.preview_image.url.should =~ %r{^/media/\w+/hello$}
  end
  
  it "should change the ext when there's an encoding step" do
    @item.preview_image = new_tempfile
    @item.save!
    item = Item.find(@item.id)
    item.preview_image.encode(:bum).url.should =~ %r{^/media/\w+/hello\.bum$}
  end
  
  it "should not include the name if it has none" do
    @item.preview_image = "HELLO"
    @item.save!
    item = Item.find(@item.id)
    item.preview_image.url.should =~ %r{^/media/\w+$}
  end
  
  it "should have an ext when there's an encoding step but no name" do
    @item.preview_image = "HELLO"
    @item.save!
    item = Item.find(@item.id)
    item.preview_image.encode(:bum).url.should =~ %r{^/media/\w+\.bum$}
  end
  
  it "should work as normal with dos protection" do
    @app.server.protect_from_dos_attacks = true
    @item.preview_image = new_tempfile
    @item.save!
    item = Item.find(@item.id)
    item.preview_image.url.should =~ %r{^/media/\w+/hello\.txt\?sha=\w+$}
  end
end