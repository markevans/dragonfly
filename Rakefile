require 'rake'

begin
  require 'jeweler'
  Jeweler::Tasks.new do |s|
    s.name = "dragonfly"
    s.summary = %Q{Dragonfly is an on-the-fly Rack processing/encoding framework.
    It includes an extension for Ruby on Rails for easy image handling}
    s.email = "mark@new-bamboo.co.uk"
    s.homepage = "http://github.com/markevans/dragonfly"
    s.authors = ["Mark Evans"]
    s.add_dependency('rack')
  end
  Jeweler::GemcutterTasks.new
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
  t.options = %w(-e yard/setup.rb)
end
YARD::Rake::YardocTask.new 'yard:changed' do |t|
  t.files   = `git status | grep '.rb' | grep modified | grep -v yard | cut -d' ' -f4`.split
  t.options = %w(-e yard/setup.rb)
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

task :default => [:spec, :features]
