# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)

Gem::Specification.new do |s|
  s.name          = 'fluent-plugin-out-solr'
  s.version       = '0.0.1'
  s.authors       = ['diogo', 'pitr', 'haruyama']
  s.email         = ['team@uken.com', 'haruyama@unixuser.org']
  s.description   = %q{Solr output plugin for Fluent event collector}
  s.summary       = s.description
  s.homepage      = 'https://github.com/haruyama/fluent-plugin-out-solr'
  s.license       = 'MIT'

  s.files         = `git ls-files`.split($/)
  s.executables   = s.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  s.test_files    = s.files.grep(%r{^(test|spec|features)/})
  s.require_paths = ['lib']

  s.add_runtime_dependency 'fluentd'

  s.add_development_dependency 'rake'
  s.add_development_dependency 'webmock'
end
