# frozen_string_literal: true

require_relative "lib/rider_kick/version"

Gem::Specification.new do |spec|
  spec.name = "rider_kick"
  spec.version = RiderKick::VERSION
  spec.authors = ["Kotaro Minami"]
  spec.email = ["kotaroisme@gmail.com"]

  spec.summary = "Clean Architecture Framework."
  spec.description = "An attempt at building a reusable Clean Architecture framework for Ruby."
  spec.homepage = "https://github.com/kotaroisme/rider_kick"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.0.0"

  spec.metadata["allowed_push_host"] = "TODO: Set to your gem server 'https://example.com'"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = spec.homepage

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  gemspec = File.basename(__FILE__)
  spec.files = IO.popen(%w[git ls-files -z], chdir: __dir__, err: IO::NULL) do |ls|
    ls.readlines("\x0", chomp: true).reject do |f|
      (f == gemspec) ||
        f.start_with?(*%w[bin/ test/ spec/ features/ .git .github appveyor Gemfile])
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  # Uncomment to register a new dependency of your gem
  # spec.add_dependency "example-gem", "~> 1.0"

  # For more information and examples about making a new gem, check out our
  # guide at: https://bundler.io/guides/creating_gem.html
  #
  ## clean arch
  spec.add_dependency 'dry-matcher', '~> 1.0.0'
  spec.add_dependency 'dry-monads', '~> 1.6.0'
  spec.add_dependency 'dry-struct', '~> 1.6.0'
  spec.add_dependency 'dry-transaction', '~> 0.16.0'
  spec.add_dependency 'dry-types', '~> 1.7.2'
  spec.add_dependency 'dry-validation', '~> 1.10.0'

  spec.add_development_dependency 'bundler', '~> 2.5.18'
  spec.add_development_dependency 'rake', '~> 13.2.1'
  spec.add_development_dependency 'rspec', '~> 3.13.0'
end
