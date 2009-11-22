require 'rake'

begin
  require 'jeweler'
  Jeweler::Tasks.new do |s|
    s.name = "dragonfly"
    s.summary = %Q{dragonfly is an on-the-fly processing/encoding framework written as a Rack application.
    It includes an extension for Ruby on Rails to enable easy image handling}
    s.email = "mark@new-bamboo.co.uk"
    s.homepage = "http://github.com/markevans/dragonfly"
    s.authors = ["Mark Evans"]
    s.add_dependency('rack')
  end
  Jeweler::Tasks.new do |s|
    s.name = "dragonfly-rails"
    s.summary = %Q{dragonfly-rails has no code of its own - it simply gathers dependencies for using dragonfly in rails}
    s.email = "mark@new-bamboo.co.uk"
    s.homepage = "http://github.com/markevans/dragonfly"
    s.authors = ["Mark Evans"]
    s.files = []
    s.test_files = []
    s.extra_rdoc_files = []
    s.add_dependency('dragonfly')
    s.add_dependency('rack')
    s.add_dependency('rack-cache')
    s.add_dependency('rmagick')
  end
rescue LoadError
  puts "Jeweler not available. Install it with: sudo gem install technicalpickles-jeweler -s http://gems.github.com"
end

require 'rake/rdoctask'
Rake::RDocTask.new do |rdoc|
  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = 'dragonfly'
  rdoc.options << '--line-numbers' << '--inline-source'
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('lib/**/*.rb')
end

require 'yard'
YARD::Rake::YardocTask.new do |t|
  t.files   = ['lib/**/*.rb']
  t.options = %w(--no-private)
end
YARD::Rake::YardocTask.new 'yard:changed' do |t|
  t.files   = `git stat | grep '.rb' | grep modified | cut -d' ' -f4`.split
  t.options = %w(--no-private)
end

require 'spec/rake/spectask'
Spec::Rake::SpecTask.new(:spec) do |t|
  t.libs << 'lib' << 'spec'
  t.spec_files = FileList['spec/**/*_spec.rb']
end

Spec::Rake::SpecTask.new(:rcov) do |t|
  t.libs << 'lib' << 'spec'
  t.spec_files = FileList['spec/**/*_spec.rb']
  t.rcov = true
end

begin
  require 'cucumber/rake/task'
  Cucumber::Rake::Task.new(:features)
rescue LoadError
  puts "Cucumber is not available. In order to run features, you must: sudo gem install cucumber"
end

task :default => :spec
