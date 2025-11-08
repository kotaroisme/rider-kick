# frozen_string_literal: true

# rider-kick.gemspec
require_relative "lib/rider_kick/version"

Gem::Specification.new do |spec|
  spec.name          = "rider-kick"
  spec.version       = RiderKick::VERSION
  spec.authors       = ["Kotaro Minami"]
  spec.email         = ["kotaroisme@gmail.com"]

  spec.summary       = "Clean Architecture generator for Ruby/Rails apps."
  spec.description   = "Rider Kick: opinionated generator to scaffold Clean Architecture (entities, use-cases, adapters) with Rails-friendly ergonomics."
  spec.homepage      = "https://github.com/kotaroisme/rider-kick"
  spec.license       = "MIT"

  spec.required_ruby_version = ">= 3.2" # naikkan jika kamu ready; kalau ragu tetap 3.1

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

  # ===== Runtime dependencies =====
  spec.add_dependency "activesupport", ">= 7.0", "< 9.0"
  spec.add_dependency "dry-matcher", ">= 1.0", "< 2.0"
  spec.add_dependency "dry-monads", ">= 1.6", "< 2.0"
  spec.add_dependency "dry-struct", ">= 1.6", "< 2.0"
  spec.add_dependency "dry-types", ">= 1.7", "< 2.0"
  spec.add_dependency "dry-validation", ">= 1.9", "< 2.0"
  spec.add_dependency "hashie", ">= 5.0", "< 6.0"
  spec.add_dependency "thor", ">= 1.2", "< 2.0"
  # NOTE: aktifkan hanya jika kamu memang memakai loader Zeitwerk DI DALAM gem.
  # Jika tidak, lebih aman dihapus agar footprint kecil.
  # spec.add_dependency "zeitwerk",      ">= 2.6", "< 3.0"

  # ===== Development/test dependencies =====
  spec.add_development_dependency "bundler",         ">= 2.4", "< 3.0"
  spec.add_development_dependency "generator_spec",  ">= 0.9",  "< 1.0"
  spec.add_development_dependency "rake",            ">= 13.0", "< 14.0"
  spec.add_development_dependency "rspec",           ">= 3.12", "< 4.0"
  spec.add_development_dependency "rubocop",         ">= 1.63", "< 2.0"
  spec.add_development_dependency "rubocop-rspec",   ">= 3.0",  "< 4.0"

  # ===== Nice-to-have metadata di RubyGems =====
  spec.metadata = {
    "homepage_uri"          => spec.homepage,
    "changelog_uri"         => "https://github.com/kotaroisme/rider-kick/blob/main/CHANGELOG.md",
    "bug_tracker_uri"       => "https://github.com/kotaroisme/rider-kick/issues",
    "rubygems_mfa_required" => "true"
  }

  spec.post_install_message = <<~MSG
    Thanks for installing rider-kick ⚡️
    Docs & examples: #{spec.homepage}
    PSA: Run `bundle exec rspec` to verify your generators and contracts.
  MSG
end
