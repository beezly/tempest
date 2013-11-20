# Ensure we require the local version and not one we might have installed already
require File.join([File.dirname(__FILE__),'lib','tempest','version.rb'])
spec = Gem::Specification.new do |s| 
  s.name = 'tempest'
  s.version = Tempest::VERSION
  s.author = 'Andrew Beresford'
  s.email = 'beezly@beezly.org.uk'
  s.homepage = 'http://github.com/beezly/tempest'
  s.platform = Gem::Platform::RUBY
  s.summary = 'CLI tool and Library for managing Riverbed Stingray Traffic Managers'
# Add your other files here if you make them
  s.files = %w(
bin/tempest
lib/tempest/version.rb
lib/tempest/stingray.rb
lib/tempest.rb
  )
  s.require_paths << 'lib'
  s.has_rdoc = true
  s.rdoc_options << '--title' << 'tempest' << '--main' << 'README.rdoc' << '-ri'
  s.bindir = 'bin'
  s.executables << 'tempest'
  s.add_development_dependency('rake')
  s.add_development_dependency('rdoc')
  s.add_development_dependency('aruba')
  s.add_runtime_dependency('gli','2.8.1')
  s.add_runtime_dependency('httparty','0.12.0')
  s.add_runtime_dependency('text-table','1.2.3')
  s.add_runtime_dependency('promise','0.3.0')
end
