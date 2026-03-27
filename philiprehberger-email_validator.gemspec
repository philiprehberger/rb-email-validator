# frozen_string_literal: true

require_relative 'lib/philiprehberger/email_validator/version'

Gem::Specification.new do |spec|
  spec.name          = 'philiprehberger-email_validator'
  spec.version       = Philiprehberger::EmailValidator::VERSION
  spec.authors       = ['Philip Rehberger']
  spec.email         = ['me@philiprehberger.com']
  spec.summary       = 'RFC-compliant email validation with MX record verification'
  spec.description   = 'Validates email addresses with RFC 5322 syntax checking, MX record verification, ' \
                       'disposable domain detection, and role-based address identification.'
  spec.homepage      = 'https://github.com/philiprehberger/rb-email-validator'
  spec.license       = 'MIT'
  spec.required_ruby_version = '>= 3.1.0'
  spec.metadata['homepage_uri']          = spec.homepage
  spec.metadata['source_code_uri']       = spec.homepage
  spec.metadata['changelog_uri']         = "#{spec.homepage}/blob/main/CHANGELOG.md"
  spec.metadata['bug_tracker_uri']       = "#{spec.homepage}/issues"
  spec.metadata['rubygems_mfa_required'] = 'true'
  spec.files = Dir['lib/**/*.rb', 'LICENSE', 'README.md', 'CHANGELOG.md']
  spec.require_paths = ['lib']
end
