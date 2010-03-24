# encoding: utf-8
require File.dirname(__FILE__) + '/../spec_helper'

describe Dragonfly::Serializer do
  
  include Dragonfly::Serializer
  
  [
    'a',
    'sdhflasd',
    '/2010/03/01/hello.png',
    '//..',
    'whats/up.egg.frog',
    '£ñçùí;'
  ].each do |string|
    it "should encode #{string.inspect} properly with no padding/line break" do
      b64_encode(string).should_not =~ /\n|=/
    end
    it "should correctly encode and decode #{string.inspect} to the same string" do
      b64_decode(b64_encode(string)).should == string
    end
  end
  
end
