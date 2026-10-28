lib = File.expand_path("lib", __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'fastlane/plugin/swiftshot/version'

Gem::Specification.new do |spec|
  spec.name          = 'fastlane-plugin-swiftshot'
  spec.version       = Fastlane::Swiftshot::VERSION
  spec.author        = 'Lukas Anda'
  spec.email         = 'lukas.anda@gmail.com'

  spec.summary       = 'Screenshots from SwiftUI, Compose and Flutter previews with Swiftshot'
  spec.description   = 'Runs the swiftshot CLI from a lane, in place of snapshot and screengrab.'
  spec.homepage      = 'https://github.com/LukasAnda/swiftshot'
  spec.license       = 'MIT'

  spec.files         = Dir["lib/**/*"] + %w(README.md LICENSE)
  spec.require_paths = ['lib']
  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = 'https://github.com/LukasAnda/fastlane-plugin-swiftshot'
  spec.metadata['bug_tracker_uri'] = 'https://github.com/LukasAnda/fastlane-plugin-swiftshot/issues'
  spec.metadata['changelog_uri'] = 'https://github.com/LukasAnda/fastlane-plugin-swiftshot/releases'
  spec.metadata['rubygems_mfa_required'] = 'true'
  spec.required_ruby_version = '>= 3.0'

  # Don't add a dependency to fastlane or fastlane_re
  # since this would cause a circular dependency
end
