# coding: utf-8
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "dragonfly/version"

Gem::Specification.new do |spec|
  spec.name = "dragonfly"
  spec.version = Dragonfly::VERSION
  spec.authors = ["Mark Evans"]
  spec.email = "mark@new-bamboo.co.uk"
  spec.description = "Dragonfly is a framework that enables on-the-fly processing for any content type.\n  It is especially suited to image handling. Its uses range from image thumbnails to standard attachments to on-demand text generation."
  spec.summary = "Ideal gem for handling attachments in Rails, Sinatra and Rack applications."
  spec.homepage = "http://github.com/markevans/dragonfly"
  spec.license = "MIT"
  spec.files = `git ls-files`.split($/)
  spec.executables = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]
  spec.extra_rdoc_files = [
    "LICENSE",
    "README.md",
  ]

  # Runtime dependencies
  spec.add_runtime_dependency("rack", ">= 1.3")
  spec.add_runtime_dependency("multi_json", "~> 1.0")
  spec.add_runtime_dependency("addressable", "~> 2.3")

  # Development dependencies
  spec.add_development_dependency("rspec", "~> 3.0")
  spec.add_development_dependency("webmock")
  spec.add_development_dependency("activemodel")
  if RUBY_PLATFORM == "java"
    spec.add_development_dependency("jruby-openssl")
  else
    spec.add_development_dependency("activerecord")
    spec.add_development_dependency("sqlite3")
  end
end
