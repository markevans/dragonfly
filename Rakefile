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
    s.add_development_dependency 'jeweler'
    s.add_development_dependency 'yard'
    s.add_development_dependency 'rmagick'
    s.add_development_dependency 'aws-s3'
    s.add_development_dependency 'rspec'
    s.add_development_dependency 'cucumber'
    s.add_development_dependency 'cucumber-rails'
    s.add_development_dependency 'activerecord'
    s.add_development_dependency 'sqlite3-ruby'
    s.add_development_dependency 'ginger'
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
    t.options = %w(-e yard/setup.rb)
  end
  YARD::Rake::YardocTask.new 'yard:changed' do |t|
    t.files   = `git status | grep '.rb' | grep modified | grep -v yard | cut -d' ' -f4`.split
    t.options = %w(-e yard/setup.rb)
  end
rescue LoadError
  puts "YARD is not available. To run the documentation tasks, install it with: (sudo) gem install yard"
end

begin
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
rescue LoadError
  puts "RSpec is not available. To run tests, install it with: (sudo) gem install rspec"
end

begin
  require 'cucumber/rake/task'
  Cucumber::Rake::Task.new(:features)
rescue LoadError
  puts "Cucumber is not available. To run features, install it with: (sudo) gem install cucumber"
end

begin
  require 'ginger'
rescue LoadError
  puts "To run 'rake', to test everything, you need the Ginger gem. Install it with: (sudo) gem install ginger"
end
task :default do
  system 'ginger spec && rake features'
end
