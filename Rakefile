require 'rubygems'
require 'bundler'
begin
  Bundler.setup(:default, :development)
rescue Bundler::BundlerError => e
  $stderr.puts e.message
  $stderr.puts "Run `bundle install` to install missing gems"
  exit e.status_code
end
require 'rake'

require 'jeweler'
Jeweler::Tasks.new do |gem|
  gem.name = "dragonfly"
  gem.email = "mark@new-bamboo.co.uk"
  gem.summary = %Q{Ideal gem for handling attachments in Rails, Sinatra and Rack applications.}
  gem.description = %Q{Dragonfly is a framework that enables on-the-fly processing for any content type.
  It is especially suited to image handling. Its uses range from image thumbnails to standard attachments to on-demand text generation.}
  gem.homepage = "http://github.com/markevans/dragonfly"
  gem.license = "MIT"
  gem.authors = ["Mark Evans"]
end
Jeweler::RubygemsDotOrgTasks.new

require 'rspec/core'
require 'rspec/core/rake_task'
RSpec::Core::RakeTask.new(:spec) do |spec|
  spec.pattern = FileList['spec/**/*_spec.rb']
end

RSpec::Core::RakeTask.new(:rcov) do |spec|
  spec.pattern = 'spec/**/*_spec.rb'
  spec.rcov = true
end

require 'cucumber/rake/task'
Cucumber::Rake::Task.new(:features)

task :default => [:spec, :features]

require 'yard'
YARD::Rake::YardocTask.new do |t|
  t.files   = ['lib/**/*.rb']
  t.options = []
end
YARD::Rake::YardocTask.new 'yard:changed' do |t|
  t.files   = `git status | grep '.rb' | grep modified | grep -v yard | cut -d' ' -f4`.split
  t.options = []
end
