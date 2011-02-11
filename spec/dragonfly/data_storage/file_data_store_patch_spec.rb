require File.expand_path File.dirname(__FILE__) + '/../../spec_helper'

describe Dragonfly::DataStorage::FileDataStore do
  describe "relative" do
    let(:store) { Dragonfly::DataStorage::FileDataStore.new }
    let(:relative_path) { "2011/02/11/picture.jpg" }
    let(:absolute_path) { "#{root_path}#{relative_path}" }
    let(:root_path) { "/path/to/file/" }

    before do
      store.root_path = root_path
    end

    subject { store.send :relative, absolute_path }

    it { should == relative_path }

    context "where root path contains spaces" do
      let(:root_path) { "/path/to/file name/" }
      it { should == relative_path }
    end
    context "where root path contains special chars" do
      let(:root_path) { "/path/to/file name (Special backup directory)/" }
      it { should == relative_path }
    end
  end
end
