# frozen_string_literal: true

# rider-kick.gemspec
require_relative "lib/rider_kick/version"

Gem::Specification.new do |spec|
  spec.name          = "rider-kick"
  spec.version       = RiderKick::VERSION
  spec.authors       = ["Kotaro Minami"]
  spec.email         = ["kotaroisme@gmail.com"]

  spec.summary       = "Clean Architecture generator for Ruby/Rails apps."
  spec.description   = <<~DESC
    Rider Kick: opinionated generator to scaffold Clean Architecture#{' '}
    (entities, use-cases, adapters) with Rails-friendly ergonomics.

    Features:
    - Clean Architecture scaffolding with domain scoping
    - Use-case-first "screaming architecture"
    - Automatic RSpec generation
    - FactoryBot factory generator with smart Faker
    - Rails engine support
    - Idempotent and safe to run multiple times
  DESC
  spec.homepage      = "https://github.com/kotaroisme/rider-kick"
  spec.license       = "MIT"
  spec.required_ruby_version = ">= 3.2"

  # File list (pastikan templates generator ikut terkirim)
  # Gunakan git ls-files untuk rilis via git agar presisi:
  spec.files = IO.popen(['git', 'ls-files', '-z'], chdir: __dir__, err: IO::NULL) { |io|
    io.read.split("\x0").select { |f|
      f.start_with?("lib/", "exe/", "README", "CHANGELOG", "LICENSE")
    }
  }
  spec.bindir        = "exe"
  spec.executables   = Dir["exe/*"].map { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  # ===== Runtime Dependencies =====
  # Dependencies yang diperlukan saat gem ini digunakan di aplikasi Rails

  # ActiveSupport: digunakan untuk inflector, core extensions, dan utilities
  spec.add_dependency "activesupport", ">= 7.0", "< 9.0"

  # Dry-rb ecosystem: digunakan untuk functional programming patterns
  spec.add_dependency "dry-matcher", ">= 1.0", "< 2.0"      # Pattern matching untuk use case results
  spec.add_dependency "dry-monads", ">= 1.6", "< 2.0"        # Result monads (Success/Failure)
  spec.add_dependency "dry-struct", ">= 1.6", "< 2.0"       # Entity classes (type-safe structs)
  spec.add_dependency "dry-types", ">= 1.7", "< 2.0"         # Type system untuk entities
  spec.add_dependency "dry-validation", ">= 1.9", "< 2.0"    # Contract validation untuk use cases

  # Hashie: digunakan untuk Hashie::Mash (flexible hash objects)
  spec.add_dependency "hashie", ">= 5.0", "< 6.0"

  # Thor: digunakan oleh Rails::Generators::Base untuk command-line interface
  spec.add_dependency "thor", ">= 1.2", "< 2.0"

  # ===== Development/Test Dependencies =====
  # Dependencies yang hanya diperlukan untuk development dan testing gem ini

  spec.add_development_dependency "bundler", ">= 2.4", "< 3.0"
  spec.add_development_dependency "generator_spec", ">= 0.9", "< 1.0"  # Testing Rails generators
  spec.add_development_dependency "rake", ">= 13.0", "< 14.0"
  spec.add_development_dependency "rspec", ">= 3.12", "< 4.0"
  spec.add_development_dependency "rubocop", ">= 1.63", "< 2.0"
  spec.add_development_dependency "rubocop-performance", ">= 1.0", "< 2.0"  # Performance linting
  spec.add_development_dependency "rubocop-rails-omakase", ">= 1.0", "< 2.0"  # Rails-specific linting
  spec.add_development_dependency "rubocop-rspec", ">= 3.0", "< 4.0"

  # Faker: digunakan di factory_generator untuk evaluate faker expressions (--static option)
  spec.add_development_dependency "faker", ">= 3.0", "< 4.0"

  # Debug: digunakan untuk debugging saat development
  spec.add_development_dependency "debug", ">= 1.0", "< 2.0"

  # ===== Metadata =====
  spec.metadata = {
    "homepage_uri"          => spec.homepage,
    "changelog_uri"         => "https://github.com/kotaroisme/rider-kick/blob/main/CHANGELOG.md",
    "bug_tracker_uri"       => "https://github.com/kotaroisme/rider-kick/issues",
    "source_code_uri"       => "https://github.com/kotaroisme/rider-kick",
    "documentation_uri"     => "https://github.com/kotaroisme/rider-kick#readme",
    "rubygems_mfa_required" => "true"
  }

  spec.post_install_message = <<~MSG
    Thanks for installing rider-kick ⚡️

    Quick start:
      rails generate rider_kick:clean_arch --setup

    Documentation: #{spec.homepage}
    PSA: Run `bundle exec rspec` to verify your generators and contracts.
  MSG
end
