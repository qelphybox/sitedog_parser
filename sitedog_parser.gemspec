require_relative 'lib/sitedog_parser/version'

Gem::Specification.new do |spec|
  spec.name          = "sitedog_parser"
  spec.version       = SitedogParser::VERSION
  spec.authors       = ["Ivan Nemytchenko"]
  spec.email         = ["nemytchenko@gmail.com"]

  spec.summary       = "Parser for converting YAML format into Ruby data structures"
  spec.description   = "A library for parsing and classifying web services, hosting, and domain data from YAML files into structured Ruby objects"
  spec.homepage      = "https://github.com/inem/sitedog-parser"
  spec.license       = "MIT"
  spec.required_ruby_version = Gem::Requirement.new(">= 3.3.7")

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = "#{spec.homepage}/blob/master/CHANGELOG.md"

  # Specify which files should be included in the gem
  spec.files = Dir[
    "lib/**/*",
    "bin/*",
    "LICENSE.txt",
    "README.md",
    "CHANGELOG.md"
  ]

  spec.bindir        = "bin"
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  # Development dependencies
  spec.add_development_dependency "bundler", "~> 2.0"
  spec.add_development_dependency "rake", "~> 13.0"
  spec.add_development_dependency "minitest", "~> 5.0"
  spec.add_development_dependency "pry", "~> 0.14.1"

  # Runtime dependencies
  spec.add_dependency "thor", "~> 1.2"  # For CLI
end