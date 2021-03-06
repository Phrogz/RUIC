# encoding: UTF-8
$: << File.expand_path("../lib", __FILE__)
require "ruic/version"

Gem::Specification.new do |s|
  s.name        = "RUIC"
  s.version     = RUIC::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Gavin Kistner"]
  s.email       = ["gavin@phrogz.net"]
  s.license     = "MIT License"
  s.summary     = %q{Library and DSL analyzing and manipulating NVIDIA DRIVE Design applications and presentations.}
  s.description = %q{RUIC is a library that understands the XML formats used by the NVIDIA DRIVE Design tool suite. In addition to APIs for analyzing and manipulating these files—the NDD portion of the library—it also includes a mini DSL for writing scripts that can be run by the `ruic` interpreter.}
  s.homepage    = "https://github.com/Phrogz/RUIC"

  s.add_runtime_dependency "nokogiri", '~> 1'
  s.add_runtime_dependency "ripl", '~> 0'
  s.add_runtime_dependency "ripl-multi_line", '~> 0'
  s.add_runtime_dependency "ripl-irb", '~> 0'

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]
  s.bindir        = 'bin'
end