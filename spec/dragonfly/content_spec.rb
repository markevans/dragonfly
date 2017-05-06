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
    it "has one from the beginning" do
      content.temp_object.should be_a(Dragonfly::TempObject)
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

    it "doesn't  interfere with other content meta" do
      content.meta = {'test' => 'one'}
      content2 = content.dup
      content2.meta['test'] = 'two'

      content.meta['test'].should == 'one'
      content2.meta['test'].should == 'two'
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
  end

  describe "mime_type" do
    context "when mime_type is stored in meta" do
      it "takes it form meta" do
        content.name = "thing.png"
        content.meta.update("mime_type" => "text/html")
        content.mime_type.should == "text/html"
      end
    end
    context "when mime_type is not stored in meta" do
      it "takes it from the extension" do
        content.name = "thing"
        content.mime_type.should == "application/octet-stream"
        content.name = "thing.png"
        content.mime_type.should == "image/png"
      end
    end
  end

  describe "process!" do
    it "calls the app's processor on itself and returns itself" do
      app.add_processor(:shizzle){}
      app.get_processor(:shizzle).should_receive(:call).with(content, 'args')
      content.process!(:shizzle, 'args').should == content
    end
  end

  describe "generate!" do
    it "calls the app's generator on itself and returns itself" do
      app.add_generator(:shizzle){}
      app.get_generator(:shizzle).should_receive(:call).with(content, 'args')
      content.generate!(:shizzle, 'args').should == content
    end
  end

  describe "analyse" do
    before do
      app.add_analyser(:len){|content| content.size }
      content.update("shizzle")
    end

    it "calls the app's analyser on itself" do
      app.get_analyser(:len).should_receive(:call).with(content).and_return(7)
      content.analyse(:len).should == 7
    end

    it "caches the result" do
      content.analyse(:len).should == 7
      app.get_analyser(:len).should_not_receive(:call)
      content.analyse(:len).should == 7
    end

    it "updates when updated (i.e. clears cache)" do
      content.analyse(:len).should == 7
      content.update("something else")
      content.analyse(:len).should == 14
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

    it "returns itself" do
      content.update('abc').should == content
    end

    it "can be updated with another content" do
      content2 = Dragonfly::Content.new(app, "a", "b" => "c")
      content.update(content2)
      content.data.should == 'a'
      content.meta['b'].should == 'c'
    end

    describe "meta name" do
      let (:object) { "HI EVERYONE" }
      let (:object_with_original_filename) {
        obj = "Hi Guys"
        def obj.original_filename; 'something.original'; end
        obj
      }

      it "is nil if there is no original_filename" do
        content.update(object)
        content.meta['name'].should be_nil
      end

      it "sets the name to the original filename" do
        content.update(object_with_original_filename)
        content.meta['name'].should == 'something.original'
      end

      it "overrides original filename with the specified name" do
        content.update(object_with_original_filename, 'name' => 'summink.else')
        content.meta['name'].should == 'summink.else'
      end

      it "doesn't override a name already there" do
        content.meta['name'] = 'already.here'
        content.update(object_with_original_filename)
        content.meta['name'].should == 'already.here'
      end
    end
  end

  describe "delegated methods to temp_object" do
    it "data" do
      content.data.should == ""
      content.update("ASDF")
      content.data.should == 'ASDF'
    end

    it "file" do
      content.file.should be_a(File)
      content.file.read.should == ""
      content.update("sdf")
      content.file.should be_a(File)
      content.file.read.should == 'sdf'
      content.file{|f| f.read.should == 'sdf'}
    end

    it "path" do
      content.path.should =~ %r{\w+/\w+}
      content.update(Pathname.new('/usr/eggs'))
      content.path.should == '/usr/eggs'
    end

    it "size" do
      content.size.should == 0
      content.update("hjk")
      content.size.should == 3
    end

    it "each" do
      str = ""
      content.each{|chunk| str << chunk }
      str.should == ""
      content.update("asdf")
      content.each{|chunk| str << chunk }
      str.should == "asdf"
    end

    describe "tempfile" do
      it "uses the name for the file extension" do
        content.update("ASDF", 'name' => 'asdf.txt')
        expect(content.tempfile.path).to match(/\.txt$/)
      end
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

    describe "generating" do
      let(:content_2) { Dragonfly::Content.new(app) }

      it "allows generating with the shell" do
        content_2.shell_generate do |path|
          "cp #{content.path} #{path}"
        end.should == content_2
        content_2.data.should == "big\nstuff"
      end

      it "allows generating without escaping" do
        content_2.shell_generate(:escape => false) do |path|
          "echo dogs >> #{path}"
        end
        content_2.data.should == "dogs\n"
      end

      it "allows setting the ext on generate" do
        content_2.shell_generate(:ext => 'txt') do |path|
          "cp #{content.path} #{path}"
        end
        content_2.path.should =~ /\.txt$/
      end
    end

  end

  describe "store" do
    it "stores itself in the app's datastore" do
      app.datastore.should_receive(:write).with(content, {})
      content.store
    end

    it "allows passing options" do
      app.datastore.should_receive(:write).with(content, :hello => 'there')
      content.store(:hello => 'there')
    end
  end

  describe "b64_data" do
    it "returns a b64 data string" do
      content.update("HELLO", "name" => "hello.txt")
      content.b64_data.should == "data:text/plain;base64,SEVMTE8=\n"
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

  describe "env" do
    it "returns the app's env" do
      content.env.should == app.env
    end
  end

  describe "inspect" do
    it "returns a string" do
      content.inspect.should =~ /Content/
    end
  end

end
