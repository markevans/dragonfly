require 'spec_helper'

describe Dragonfly::Analyser do

  let(:analyser) { Dragonfly::Analyser.new }
  let(:app) { test_app }
  let(:content) { Dragonfly::Content.new(app, 'HELLO') }

  describe "cache" do

    def it_should_analyse_using(name, content, *args)
      result = mock('result')
      analyser.get(name).should_receive(:call).with(content, *args).exactly(:once).and_return result
      analyser.analyse(name, content, *args).should == result
      result
    end

    before(:each) do
      analyser.add(:blah){}
      analyser.add(:egghead){}
    end

    it "should do the analysis the first time" do
      it_should_analyse_using(:blah, content, :arg1)
    end

    describe "when already called" do
      before(:each) do
        @result = it_should_analyse_using(:blah, content, :arg1)
      end

      it "should not do it subsequent times but still return the result" do
        analyser.get(:blah).should_not_receive(:call)
        analyser.analyse(:blah, content, :arg1).should == @result
        analyser.analyse(:blah, content, :arg1).should == @result
      end

      it "should not use the cache if the content is different" do
        content = Dragonfly::Content.new(app, 'HELLO')
        it_should_analyse_using(:blah, content, :arg1)
      end

      it "should not use the cache if the method name is different" do
        it_should_analyse_using(:egghead, content, :arg1)
      end

      it "should not use the cache if the args are different" do
        it_should_analyse_using(:blah, content, :arg2)
      end

      it "should do it again if the cache has been cleared" do
        analyser.clear_cache!
        it_should_analyse_using(:blah, content, :arg1)
      end

      it "should not use the cache if it has been turned off" do
        analyser.cache_size = 0
        it_should_analyse_using(:blah, content, :arg1)
      end

    end

    describe "cache size" do
      it "should not exceed the cache size" do
        analyser.cache_size = 2

        res1 = it_should_analyse_using(:blah, content, :arg1)
        res2 = it_should_analyse_using(:blah, content, :arg2)
        res3 = it_should_analyse_using(:blah, content, :arg3) # Should kick out first one

        it_should_analyse_using(:blah, content, :arg1)

        # Third analysis should still be cached
        analyser.should_not_receive(:call_last)
        analyser.analyse(:blah, content, :arg3).should == res3
      end
    end

  end

end
