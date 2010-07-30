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

task :default do
  raise "TODO: run everything!"
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
