# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "thespian/version"

Gem::Specification.new do |s|
  s.name        = "thespian"
  s.version     = Thespian::VERSION
  s.authors     = ["Christopher J. Bottaro"]
  s.email       = ["cjbottaro@alumni.cs.utexas.edu"]
  s.homepage    = "https://github.com/cjbottaro/thespian"
  s.summary     = %q{Implementation of actor pattern using threads}
  s.description = %q{Ruby implementation of actor pattern built on threads}

  s.rubyforge_project = "thespian"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  # specify any dependencies here; for example:
  s.add_development_dependency "rspec"
  s.add_development_dependency "rr"
  s.add_development_dependency "rdoc"
  s.add_development_dependency "rake"
  # s.add_runtime_dependency "rest-client"
end
