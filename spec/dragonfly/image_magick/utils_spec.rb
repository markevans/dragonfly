require 'spec_helper'

describe Dragonfly::ImageMagick::Utils do
  
  let (:analyser) { Dragonfly::ImageMagick::Analyser.new }
  let (:scanner)  { stub(:scan => 'myimage.png PNG 200x100 200x100+0+0 8-bit DirectClass 31.2kb') }
  let (:image)    { Dragonfly::TempObject.new(SAMPLES_DIR.join('beach.png')) }
  
  describe 'smart dimensions' do
  
    before(:each) do
      analyser.stub(:smart_dimensions => true)
    end

    it 'does not look up orientation if smart_dimensions is false' do
      analyser.stub(:smart_dimensions => false)
      analyser.stub_chain(:raw_identify).and_return(scanner)
      analyser.should_not_receive(:raw_identify).with(image, "-format '%[exif:orientation]'")
      analyser.width(image)
    end
    
    it 'looks up orientation if smart_dimensions is true' do
      analyser.stub_chain(:raw_identify).and_return(scanner)
      analyser.should_receive(:raw_identify).with(image, "-format '%[exif:orientation]'").and_return(1)
      analyser.width(image)
    end
    
    it 'returns the correct dimensions for exif-tagged landscape images' do
      (1..8).each do |flag|
        exif_img = Dragonfly::TempObject.new(SAMPLES_DIR.join('exif_orientation', "landscape_#{flag}.jpg"))
        analyser.width(exif_img).should  == 600
        analyser.height(exif_img).should == 450
      end
    end
    
    it 'returns the correct dimensions for exif-tagged portrait images' do
      (1..8).each do |flag|
        exif_img = Dragonfly::TempObject.new(SAMPLES_DIR.join('exif_orientation', "portrait_#{flag}.jpg"))
        analyser.width(exif_img).should  == 450
        analyser.height(exif_img).should == 600
      end
    end
    
  end
  
end