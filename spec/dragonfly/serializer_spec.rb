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
  
  [
    :hello,
    nil,
    true,
    4,
    2.3,
    'wassup man',
    [3,4,5],
    {:wo => 'there'},
    [{:this => 'should', :work => [3, 5.3, nil, {false => 'egg'}]}, [], true]
  ].each do |object|
    it "should correctly marshal encode #{object.inspect} properly with no padding/line break" do
      encoded = marshal_encode(object)
      # raise encoded.index("\n").inspect
      encoded.should be_a(String)
      encoded.should_not =~ /\n|=/
    end
    it "should correctly marshal encode and decode #{object.inspect} to the same object" do
      marshal_decode(marshal_encode(object)).should == object
    end
  end
  
end
