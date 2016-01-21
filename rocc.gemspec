# Ensure we require the local version and not one we might have installed already
require File.join([File.dirname(__FILE__),'lib','rocc','version.rb'])
spec = Gem::Specification.new do |s| 
  s.name = 'rocc'
  s.version = Rocc::VERSION
  s.author = 'Thilo Fischer'
  s.email = 'thilo-fischer@gmx.de'
#  s.homepage = 'http://your.website.com'
  s.platform = Gem::Platform::RUBY
  s.summary = 'Swiss army knive commend line tool to operate on C-ish source code.'
  s.files = `git ls-files`.split("
")
  s.require_paths << 'lib'
  s.has_rdoc = true
  s.extra_rdoc_files = ['README.rdoc','rocc.rdoc']
  s.rdoc_options << '--title' << 'rocc' << '--main' << 'README.rdoc' << '-ri'
  s.bindir = 'bin'
  s.executables << 'rocc'
  s.add_development_dependency('rake')
  s.add_development_dependency('rdoc')
  s.add_development_dependency('cucumber')
  s.add_development_dependency('aruba')
#  s.add_runtime_dependency('gli','2.9.0')
end
