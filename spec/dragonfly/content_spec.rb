require 'spec_helper'

describe Dragonfly::Content do

  let(:app) { test_app }

  let(:content) { Dragonfly::Content.new(app) }

  describe "initializing" do
    it "allows initializing with content and meta" do
      content = Dragonfly::Content.new(app, "things", 'some' => 'meta')
      content.data.should == 'things'
      content.meta.should == {'some' => 'meta'}
    end
  end

  describe "temp_object" do
    it "starts as nil" do
      content.temp_object.should == nil
    end
  end

  describe "meta" do
    it "defaults to an empty hash" do
      content.meta.should == {}
    end

    it "sets meta" do
      content.meta = {"hello" => 'there'}
      content.meta.should == {"hello" => 'there'}
    end

    it "adds meta and returns itself" do
      content.meta = {'hello' => 'there'}
      content.add_meta('wassup' => 'guys?').should == content
      content.meta.should == {'hello' => 'there', 'wassup' => 'guys?'}
    end
  end

  describe "name" do
    it "defaults to nil" do
      content.name.should be_nil
    end

    it "gets taken from the meta" do
      content.meta["name"] = 'some.name'
      content.name.should == 'some.name'
    end

    it "has basename/name/ext setters" do
      content.name = 'hello.there'
      content.name.should == 'hello.there'
      content.basename.should == 'hello'
      content.ext.should == 'there'
      content.ext = 'schmo'
      content.name.should == 'hello.schmo'
    end

    it "falls back to the temp_object original_filename" do
      content.should_receive(:temp_object).at_least(:once).and_return(mock('temp_object', :original_filename => 'something.original'))
      content.name.should == "something.original"
      content.basename.should == 'something'
      content.ext.should == 'original'
    end
  end

  describe "process!" do
    it "calls the app's processor on itself and returns itself" do
      content.processor.should_receive(:process).with(:shizzle, content, 'args')
      content.process!(:shizzle, 'args').should == content
    end
  end

  describe "analyse" do
    it "calls the app's analyser on itself" do
      content.analyser.should_receive(:analyse).with(:shizzle, content, 'args')
      content.analyse(:shizzle, 'args')
    end
  end

  describe "update" do
    it "updates the content" do
      content.update("stuff")
      content.data.should == 'stuff'
    end

    it "optionally updates the meta" do
      content.update("stuff", 'meta' => 'here')
      content.meta.should == {'meta' => 'here'}
    end

    it "sets the name on the temp_object if present" do
      content.update("adsf")
      content.temp_object.name.should be_nil
      content.update("adsf", "name" => 'good.stuff')
      content.temp_object.name.should == "good.stuff"
    end

    it "returns itself" do
      content.update('abc').should == content
    end
  end

  describe "delegated methods to temp_object" do
    it "data" do
      content.data.should be_nil
      content.update("ASDF")
      content.data.should == 'ASDF'
    end

    it "file" do
      content.file.should == nil
      content.update("sdf")
      content.file.should be_a(File)
      content.file.read.should == 'sdf'
      content.file{|f| f.read.should == 'sdf'}
    end

    it "tempfile" do
      content.tempfile.should == nil
      content.update("sdf")
      content.tempfile.should be_a(Tempfile)
    end

    it "path" do
      content.path.should be_nil
      content.update(Pathname.new('/usr/eggs'))
      content.path.should == '/usr/eggs'
    end

    it "size" do
      content.size.should be_nil
      content.update("hjk")
      content.size.should == 3
    end

    it "to_file" do
      expect{ content.to_file }.to raise_error(Dragonfly::Content::NoContent)
      content.update("asdf")
      content.temp_object.should_receive(:to_file).and_return(file=mock)
      content.to_file.should == file
    end

    it "each" do
      str = ""
      content.each{|chunk| str << chunk }
      str.should == ""
      content.update("asdf")
      content.each{|chunk| str << chunk }
      str.should == "asdf"
    end

  end

  describe "shell commands" do
    let (:content) { Dragonfly::Content.new(app, "big\nstuff", 'name' => 'content.jpg') }

    it "evalutes using the shell" do
      path = nil
      content.shell_eval do |p|
        path = p
        "cat #{path}"
      end.should == "big\nstuff"
      path.should == app.shell.quote(content.path)
    end

    it "allows evaluating without escaping" do
      path = nil
      content.shell_eval(:escape => false) do |p|
        path = p
        %{$(echo cat) #{path}}
      end.should == "big\nstuff"
      path.should == content.path
    end

    it "runs the shell command with a new tempfile path, returning self" do
      original_path = content.path
      old_path = nil
      new_path = nil
      content.shell_update do |o, n|
        old_path = o
        new_path = n
        "cp #{o} #{n}"
      end.should == content
      old_path.should == app.shell.quote(original_path)
      new_path.should == app.shell.quote(content.path)
      content.data.should == "big\nstuff"
    end

    it "allows updating without escaping" do
      original_path = content.path
      old_path = nil
      new_path = nil
      content.shell_update(:escape => false) do |o, n|
        old_path = o
        new_path = n
        "cat #{o} > #{n}"
      end.should == content
      old_path.should == original_path
      new_path.should == content.path
      content.data.should == "big\nstuff"
    end

    it "defaults the extension to the same" do
      content.shell_update do |old_path, new_path|
        "cp #{old_path} #{new_path}"
      end
      content.path.should =~ /\.jpg$/
    end

    it "allows changing the new_path file extension" do
      content.shell_update :ext => 'png' do |old_path, new_path|
        "cp #{old_path} #{new_path}"
      end
      content.path.should =~ /\.png$/
    end
  end

  describe "close" do
    before(:each) do
      @app = test_app
      @app.add_processor(:upcase){|c| c.update("HELLO") }
      @content = Dragonfly::Content.new(@app, "hello")
      @temp_object1 = @content.temp_object
      @content.process!(:upcase)
      @temp_object2 = @content.temp_object
      @temp_object1.should_not == @temp_object2 # just checking
    end

    it "should clean up tempfiles for the last temp_object" do
      @temp_object2.should_receive(:close)
      @content.close
    end

    it "should clean up tempfiles for previous temp_objects" do
      @temp_object1.should_receive(:close)
      @content.close
    end
  end

end
