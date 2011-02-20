require 'spec_helper'

describe Dragonfly::HashWithCssStyleKeys do
  
  before(:each) do
    @hash = Dragonfly::HashWithCssStyleKeys[
      :font_style => 'normal',
      :'font-weight' => 'bold',
      'font_colour' => 'white',
      'font-size' => 23,
      :hello => 'there'
    ]
  end

  describe "accessing using underscore symbol style" do
    it{ @hash[:font_style].should == 'normal' }
    it{ @hash[:font_weight].should == 'bold' }
    it{ @hash[:font_colour].should == 'white' }
    it{ @hash[:font_size].should == 23 }
    it{ @hash[:hello].should == 'there' }
    it{ @hash[:non_existent_key].should be_nil }
  end

end
