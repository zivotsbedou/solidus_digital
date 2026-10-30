# frozen_string_literal: true

require_relative "lib/solidus_digital/version"

Gem::Specification.new do |spec|
  spec.name = "solidus_digital"
  spec.version = SolidusDigital::VERSION
  spec.summary = "Digital download functionality for Solidus"
  spec.description = spec.summary
  spec.license = "BSD-3-Clause"

  spec.author = ["funkensturm", "Michael Bianco"]
  spec.email = "info@cliffsidedev.com"
  spec.homepage = "https://github.com/solidusio-contrib/solidus_digital"

  if spec.respond_to?(:metadata)
    spec.metadata["homepage_uri"] = spec.homepage if spec.homepage
    spec.metadata["source_code_uri"] = spec.homepage if spec.homepage
  end

  spec.required_ruby_version = ">= 3.2"

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "deface", "~> 1.9"
  spec.add_dependency "prawn", "~> 2.5"
  spec.add_dependency "solidus_core", [">= 4.8", "< 5"]
  spec.add_dependency "solidus_support", [">= 0.14.1", "< 1"]

  spec.add_development_dependency "pdf-reader"
  spec.add_development_dependency "rspec-activemodel-mocks"
  spec.add_development_dependency "shoulda-matchers"
  spec.add_development_dependency "solidus_dev_support"
end
