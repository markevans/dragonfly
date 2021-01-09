# jruby has problems with installing sqlite3 - don't bother with these tests for jruby
unless RUBY_PLATFORM != "java"
  require "spec_helper"
  require "active_record"

  # ActiveRecord specific stuff goes here (there should be very little!)
  describe "ActiveRecord models" do
    let! :dragonfly_app do test_app(:test_ar) end

    before :all do
      @connection = ActiveRecord::Base.establish_connection(:adapter => "sqlite3", :database => ":memory:")

      ActiveRecord::Migration.verbose = false

      ActiveRecord::Schema.define(:version => 1) do
        create_table :photos do |t|
          t.string :image_uid
        end
      end

      class Photo < ActiveRecord::Base
        extend Dragonfly::Model
        dragonfly_accessor :image, app: :test_ar
      end
    end

    after :all do
      Photo.destroy_all
      ActiveRecord::Base.remove_connection(@connection)
    end

    describe "destroying" do
      before do
        Photo.destroy_all
        @photo = Photo.create(image: "some data")
      end

      def data_exists(uid)
        !!dragonfly_app.datastore.read(uid)
      end

      it "should not remove the attachment if a transaction is cancelled" do
        Photo.transaction do
          @photo.destroy
          raise ActiveRecord::Rollback
        end
        photo = Photo.last
        expect(photo.image_uid).not_to be_nil
        expect(data_exists(photo.image_uid)).to eq(true)
      end

      it "should remove the attachment as per usual otherwise" do
        uid = @photo.image_uid
        @photo.destroy
        photo = Photo.last
        expect(photo).to be_nil
        expect(data_exists(uid)).to eq(false)
      end
    end
  end
end
