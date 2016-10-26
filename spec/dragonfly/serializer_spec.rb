# encoding: utf-8
require 'spec_helper'

describe Dragonfly::Serializer do

  include Dragonfly::Serializer

  describe "base 64 encoding/decoding" do
    [
      'a',
      'sdhflasd',
      '/2010/03/01/hello.png',
      '//..',
      'whats/up.egg.frog',
      '£ñçùí;',
      '~',
      '-umlaut_ö'
    ].each do |string|
      it "should encode #{string.inspect} properly with no padding/line break or slash" do
        b64_encode(string).should_not =~ /\n|=|\//
      end
      it "should correctly encode and decode #{string.inspect} to the same string" do
        str = b64_decode(b64_encode(string))
        str.force_encoding('UTF-8') if str.respond_to?(:force_encoding)
        str.should == string
      end
    end

    describe "b64_decode" do
      if RUBY_PLATFORM != 'java'
        # jruby doesn't seem to throw anything - it just removes non b64 characters
        it "raises an error if the string passed in is not base 64" do
          expect {
            b64_decode("eggs for breakfast")
          }.to raise_error(Dragonfly::Serializer::BadString)
        end
      end
      it "converts (deprecated) '~' and '/' characters to '_' characters" do
        b64_decode('LXVtbGF1dF~Dtg').should == b64_decode('LXVtbGF1dF_Dtg')
        b64_decode('LXVtbGF1dF/Dtg').should == b64_decode('LXVtbGF1dF_Dtg')
      end
      it "converts '+' characters to '-' characters" do
        b64_decode('LXVtbGF1dF+Dtg').should == b64_decode('LXVtbGF1dF-Dtg')
      end
    end
  end

  describe "marshal_b64_decode" do
    it "should raise an error if the string passed in is empty" do
      lambda{
        marshal_b64_decode('')
      }.should raise_error(Dragonfly::Serializer::BadString)
    end
    it "should raise an error if the string passed in is gobbledeegook" do
      lambda{
        marshal_b64_decode('ahasdkjfhasdkfjh')
      }.should raise_error(Dragonfly::Serializer::BadString)
    end
    describe "potentially harmful strings" do
      ['_', 'hello', 'h2', '__send__', 'F'].each do |variable_name|
        it "raises if it finds a malicious string" do
          class C; end
          c = C.new
          c.instance_eval{ instance_variable_set("@#{variable_name}", 1) }
          string = Dragonfly::Serializer.b64_encode(Marshal.dump(c))
          lambda{
            marshal_b64_decode(string)
          }.should raise_error(Dragonfly::Serializer::MaliciousString)
        end
      end
    end
  end

  [
    [3,4,5],
    {'wo' => 'there'},
    [{'this' => 'should', 'work' => [3, 5.3, nil, {'egg' => false}]}, [], true]
  ].each do |object|
    it "should correctly json encode #{object.inspect} properly with no padding/line break" do
      encoded = json_b64_encode(object)
      encoded.should be_a(String)
      encoded.should_not =~ /\n|=/
    end

    it "should correctly json encode and decode #{object.inspect} to the same object" do
      json_b64_decode(json_b64_encode(object)).should == object
    end
  end

  describe "json_b64_decode" do
    it "should raise an error if the string passed in is empty" do
      lambda{
        json_b64_decode('')
      }.should raise_error(Dragonfly::Serializer::BadString)
    end
    it "should raise an error if the string passed in is gobbledeegook" do
      lambda{
        json_b64_decode('ahasdkjfhasdkfjh')
      }.should raise_error(Dragonfly::Serializer::BadString)
    end
  end

end
