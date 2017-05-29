# -*- encoding: utf-8 -*-
require 'English'

$LOAD_PATH.push File.expand_path('../lib', __FILE__)

Gem::Specification.new do |s|
  s.name          = 'fluent-plugin-out-solr'
  s.version       = '0.0.8'
  s.authors       = %w(diogo pitr haruyama)
  s.email         = ['haruyama@unixuser.org']
  s.description   = %q(Solr output plugin for Fluent event collector)
  s.summary       = s.description
  s.homepage      = 'https://github.com/haruyama/fluent-plugin-out-solr'
  s.license       = 'MIT'

  s.files         = `git ls-files`.split($INPUT_RECORD_SEPARATOR)
  s.executables   = s.files.grep(/^bin\//).map { |f| File.basename(f) }
  s.test_files    = s.files.grep(/^(test|spec|features)\//)
  s.require_paths = ['lib']

  s.add_runtime_dependency 'fluentd'

  s.add_development_dependency 'rake'
  s.add_development_dependency 'webmock'
  s.add_development_dependency 'test-unit', '~> 3.2'
  s.add_development_dependency 'minitest', '~> 5.0'
end
