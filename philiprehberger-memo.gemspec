# frozen_string_literal: true

require_relative 'lib/philiprehberger/memo/version'

Gem::Specification.new do |spec|
  spec.name          = 'philiprehberger-memo'
  spec.version       = Philiprehberger::Memo::VERSION
  spec.authors       = ['Philip Rehberger']
  spec.email         = ['me@philiprehberger.com']

  spec.summary       = 'Practical memoization with TTL, LRU eviction, and thread-safety'
  spec.description   = 'Memoize methods with a simple decorator. Supports TTL expiration, ' \
                       'LRU eviction, thread-safe per-instance caches, and proper nil/false handling.'
  spec.homepage      = 'https://github.com/philiprehberger/rb-memo'
  spec.license       = 'MIT'

  spec.required_ruby_version = '>= 3.1.0'

  spec.metadata['homepage_uri']    = spec.homepage
  spec.metadata['source_code_uri'] = spec.homepage
  spec.metadata['changelog_uri']   = "#{spec.homepage}/blob/main/CHANGELOG.md"
  spec.metadata['bug_tracker_uri']       = "#{spec.homepage}/issues"
  spec.metadata['rubygems_mfa_required'] = 'true'

  spec.files = Dir['lib/**/*.rb', 'LICENSE', 'README.md', 'CHANGELOG.md']
  spec.require_paths = ['lib']
end
