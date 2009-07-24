# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{redcap}
  s.version = "0.7.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Paul Morganthall"]
  s.date = %q{2009-07-23}
  s.email = %q{slothbear@constella.org}
  s.executables = ["redcap", "redcap.log"]
  s.extra_rdoc_files = [
    "LICENSE",
     "README.rdoc"
  ]
  s.files = [
    ".document",
     ".gitignore",
     "LICENSE",
     "README.rdoc",
     "Rakefile",
     "VERSION",
     "bin/redcap",
     "doc/placeholder",
     "lib/redcap/uploader.rb",
     "test/redcap_image.jpc",
     "test/redcap_test.rb",
     "test/synapse.jpg",
     "test/test_helper.rb",
     "test/test_llsd.rb",
     "test/test_nextpowerof2.rb",
     "test/test_parsecap.rb",
     "test/test_ticket.rb"
  ]
  s.homepage = %q{http://adammarker.org/redcap}
  s.rdoc_options = ["--charset=UTF-8"]
  s.require_paths = ["lib"]
  s.required_ruby_version = Gem::Requirement.new(">= 1.8")
  s.rubygems_version = %q{1.3.1}
  s.summary = %q{Utilities for uploading images to Second Life}
  s.test_files = [
    "test/redcap_test.rb",
     "test/test_helper.rb",
     "test/test_llsd.rb",
     "test/test_nextpowerof2.rb",
     "test/test_parsecap.rb",
     "test/test_ticket.rb"
  ]

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 2

    if Gem::Version.new(Gem::RubyGemsVersion) >= Gem::Version.new('1.2.0') then
    else
    end
  else
  end
end
