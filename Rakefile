require 'rake'

begin
  require 'jeweler'
  Jeweler::Tasks.new do |s|
    s.name = "dragonfly"
    s.summary = %Q{Dragonfly is an on-the-fly Rack-based image handling framework.
    It is suitable for use with Rails, Sinatra and other web frameworks. Although it's mainly used for images,
    it can handle any content type.}
    s.email = "mark@new-bamboo.co.uk"
    s.homepage = "http://github.com/markevans/dragonfly"
    s.authors = ["Mark Evans"]
    s.add_dependency('rack')
  end
  Jeweler::GemcutterTasks.new
rescue LoadError
  puts "Jeweler not available. Install it with: (sudo) gem install jeweler"
end

require 'rake/rdoctask'
Rake::RDocTask.new do |rdoc|
  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = 'dragonfly'
  rdoc.options << '--line-numbers' << '--inline-source'
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('lib/**/*.rb')
end

begin
  require 'yard'
  YARD::Rake::YardocTask.new do |t|
    t.files   = ['lib/**/*.rb']
    t.options = []
  end
  YARD::Rake::YardocTask.new 'yard:changed' do |t|
    t.files   = `git status | grep '.rb' | grep modified | grep -v yard | cut -d' ' -f4`.split
    t.options = []
  end
rescue LoadError
  puts "YARD is not available. To run the documentation tasks, install it with: (sudo) gem install yard"
end

desc "Run all the specs"
task :spec do
  system "bundle exec spec -O .specopts spec/dragonfly"
end

desc "Run the active model specs"
task :model_spec do
  system "bundle exec spec -O .specopts spec/dragonfly/active_model_extensions"
end

desc "Run the active_record specs (AR 2.3)"
task :model_spec_235 do
  system "export BUNDLE_GEMFILE=Gemfile.rails.2.3.5 && bundle exec spec -O .specopts spec/dragonfly/active_model_extensions"
end

task :features do
  system "bundle exec cucumber"
end

task :default do
  # Do everything!!!
  puts "*** Running all the specs using the default Gemfile ***"
  Rake::Task['spec'].invoke
  puts "*** Running the model specs with Gemfile.rails.2.3.5 ***"
  Rake::Task['model_spec_235'].invoke
  puts "*** Running the features ***"
  Rake::Task['features'].invoke
end

desc 'Set up a Rails app ready for testing'
namespace :rails do

  task :setup do
    version = ENV['RAILS_VERSION']
    raise "Please give a RAILS_VERSION, e.g. RAILS_VERSION=2.3.5" unless version
    path = File.expand_path("fixtures/rails_#{version}")
    app_name = 'tmp_app'
    system %(
      cd #{path} &&
      rm -rf #{app_name} &&
      ../rails _#{version}_ #{app_name} -m template.rb
    )
    FileUtils.cp("fixtures/dragonfly_setup.rb", "#{path}/#{app_name}/config/initializers")
    system %(cd #{path}/#{app_name} && rake db:migrate)
    puts "*** Created a Rails #{version} app in #{path}/#{app_name} ***"
    puts "Now just start the server, and go to localhost:3000/albums"
    puts "***"
  end

end
