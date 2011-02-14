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

desc "Run all the features"
task :features do
  system "bundle exec cucumber"
end

task :default do
  # Do everything!!!
  puts "*** Running the specs ***"
  Rake::Task['spec'].invoke
  puts "*** Running the features ***"
  Rake::Task['features'].invoke
end
