# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'idb/version'

Gem::Specification.new do |spec|
  spec.name          = "idb"
  spec.version       = Idb::VERSION
  spec.authors       = ["Daniel A. Mayer"]
  spec.email         = ["mayer@cysec.org"]
  spec.summary       = %q{idb is a tool to simplify some common tasks for iOS pentesting and research.}
  spec.description   = %q{idb is a tool to simplify some common tasks for iOS pentesting and research. Please see https://github.com/dmayer/idb for more details on installation and usage.}
  spec.homepage      = "https://github.com/dmayer/idb"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.6"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "pry"
  spec.add_development_dependency "pry-byebug"

  spec.add_runtime_dependency 'launchy'
  spec.add_runtime_dependency 'plist4r'
  spec.add_runtime_dependency 'net-ssh'
  spec.add_runtime_dependency 'net-sftp'
  spec.add_runtime_dependency 'nokogiri'
  spec.add_runtime_dependency 'sqlite3'
  spec.add_runtime_dependency 'coderay'
  spec.add_runtime_dependency 'qtbindings'
  spec.add_runtime_dependency 'awesome_print'
  spec.add_runtime_dependency 'htmlentities'
  spec.add_runtime_dependency 'log4r'
  spec.add_runtime_dependency 'git'
  spec.add_runtime_dependency 'hexdump'
  spec.add_runtime_dependency 'json'
end
