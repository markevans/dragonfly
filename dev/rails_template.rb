gem 'dragonfly', :path => File.expand_path('../..', __FILE__)
generate "dragonfly"
generate "scaffold", "photo image_uid:string image_name:string"
rake "db:migrate"
route %(
  get "text/:text" => Dragonfly.app.endpoint { |params, app|
    app.generate(:text, params[:text])
  }
)
route "root :to => 'photos#index'"
run "rm -rf public/index.html"

possible_base_classes = ['ActiveRecord::Base', 'ApplicationRecord']
possible_base_classes.each do |base_class|
  inject_into_file 'app/models/photo.rb', :after => "class Photo < #{base_class}\n" do
    %(
      attr_accessible :image rescue nil
      dragonfly_accessor :image
    )
  end
end

gsub_file 'app/views/photos/_form.html.erb', /^.*:image_.*$/, ''

inject_into_file 'app/views/photos/_form.html.erb', :before => %(<div class="actions">\n) do
  %(
    <div class="field">
      <%= f.label :image %><br>
      <%= f.file_field :image %>
    </div>

    <%= image_tag @photo.image.thumb('100x100').url if @photo.image_uid %>
  )
end

gsub_file "app/controllers/photos_controller.rb", "permit(", "permit(:image, "

append_file 'app/views/photos/show.html.erb', %(
 <%= image_tag @photo.image.thumb('300x300').url if @photo.image_uid? %>
)
