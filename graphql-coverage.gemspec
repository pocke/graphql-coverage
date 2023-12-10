# frozen_string_literal: true

require_relative "lib/graphql/coverage/version"

Gem::Specification.new do |spec|
  spec.name = "graphql-coverage"
  spec.version = GraphQL::Coverage::VERSION
  spec.authors = ["Masataka Pocke Kuwabara"]
  spec.email = ["kuwabara@pocke.me"]

  spec.summary = "Coverage for GraphQL"
  spec.description = "Coverage for GraphQL"
  spec.homepage = "https://github.com/pocke/graphql-coverage"
  spec.required_ruby_version = ">= 3.0"
  spec.license = "MIT"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = "https://github.com/pocke/graphql-coverage/blob/master/CHANGELOG.md"

  spec.metadata['rubygems_mfa_required'] = 'true'

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(__dir__) do
    `git ls-files -z`.split("\x0").reject do |f|
      (File.expand_path(f) == __FILE__) ||
        f.start_with?(*%w[bin/ test/ spec/ features/ .git .github appveyor Gemfile])
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "graphql", ">= 2"
end
