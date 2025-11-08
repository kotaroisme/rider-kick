# frozen_string_literal: true

require 'rails/generators'
require 'tmpdir'
require 'fileutils'
require 'generators/rider_kick/clean_arch_generator'

RSpec.describe 'rider_kick:clean_arch generator with engine option' do
  let(:klass) { RiderKick::CleanArchGenerator }

  context 'without --engine option (main app)' do
    it 'uses main app models path when no engine specified' do
      Dir.mktmpdir do |dir|
        Dir.chdir(dir) do
          FileUtils.mkdir_p('config')
          File.write('Gemfile', "source 'https://rubygems.org'\n")

          # Reset configuration untuk test
          RiderKick.configuration.engine_name = nil

          instance = klass.new([])
          opts = double('options', setup: true)
          allow(opts).to receive(:[]).and_return(nil)
          allow(opts).to receive(:[]).with(:engine).and_return(nil)
          allow(opts).to receive(:[]).with(:quiet).and_return(false)
          allow(instance).to receive(:options).and_return(opts)

          # Hanya test setup_domain_structure yang relevan dengan engine configuration
          allow(instance).to receive(:copy_domain_file) # Skip template yang memerlukan Rails
          allow(instance).to receive(:setup_initializers) # Skip initializers yang memerlukan Rails
          allow(instance).to receive(:setup_dotenv)
          allow(instance).to receive(:setup_gitignore)
          allow(instance).to receive(:setup_rubocop)
          allow(instance).to receive(:setup_init_migration)
          allow(instance).to receive(:setup_active_storage)
          allow(instance).to receive(:setup_rspec)
          allow(instance).to receive(:setup_readme)
          allow(instance).to receive(:create_gem_dependencies)
          allow(instance).to receive(:run)

          instance.setup_configuration

          # Verifikasi models_path menggunakan main app
          expect(RiderKick.configuration.models_path).to eq('app/models/models')
          expect(RiderKick.configuration.engine_name).to be_nil
        end
      end
    end
  end

  context 'with --engine option' do
    it 'uses engine models path when engine specified' do
      Dir.mktmpdir do |dir|
        Dir.chdir(dir) do
          FileUtils.mkdir_p('config')
          File.write('Gemfile', "source 'https://rubygems.org'\n")

          # Reset configuration untuk test
          RiderKick.configuration.engine_name = nil

          instance = klass.new([])
          opts = double('options', setup: true)
          allow(opts).to receive(:[]).and_return(nil)
          allow(opts).to receive(:[]).with(:engine).and_return('Core')
          allow(opts).to receive(:[]).with(:quiet).and_return(false)
          allow(instance).to receive(:options).and_return(opts)

          # Hanya test setup_domain_structure yang relevan dengan engine configuration
          allow(instance).to receive(:copy_domain_file) # Skip template yang memerlukan Rails
          allow(instance).to receive(:setup_initializers) # Skip initializers yang memerlukan Rails
          allow(instance).to receive(:setup_dotenv)
          allow(instance).to receive(:setup_gitignore)
          allow(instance).to receive(:setup_rubocop)
          allow(instance).to receive(:setup_init_migration)
          allow(instance).to receive(:setup_active_storage)
          allow(instance).to receive(:setup_rspec)
          allow(instance).to receive(:setup_readme)
          allow(instance).to receive(:create_gem_dependencies)
          allow(instance).to receive(:run)

          instance.setup_configuration

          # Verifikasi models_path menggunakan engine
          expect(RiderKick.configuration.models_path).to eq('app/models/core')
          expect(RiderKick.configuration.engine_name).to eq('Core')
        end
      end
    end

    it 'creates models directory with correct engine path' do
      Dir.mktmpdir do |dir|
        Dir.chdir(dir) do
          FileUtils.mkdir_p('config')
          File.write('Gemfile', "source 'https://rubygems.org'\n")

          # Reset configuration untuk test
          RiderKick.configuration.engine_name = nil

          instance = klass.new([])
          opts = double('options', setup: true)
          allow(opts).to receive(:[]).and_return(nil)
          allow(opts).to receive(:[]).with(:engine).and_return('Admin')
          allow(opts).to receive(:[]).with(:quiet).and_return(false)
          allow(instance).to receive(:options).and_return(opts)

          # Hanya test setup_domain_structure yang relevan dengan engine configuration
          allow(instance).to receive(:copy_domain_file) # Skip template yang memerlukan Rails
          allow(instance).to receive(:setup_initializers) # Skip initializers yang memerlukan Rails
          allow(instance).to receive(:setup_dotenv)
          allow(instance).to receive(:setup_gitignore)
          allow(instance).to receive(:setup_rubocop)
          allow(instance).to receive(:setup_init_migration)
          allow(instance).to receive(:setup_active_storage)
          allow(instance).to receive(:setup_rspec)
          allow(instance).to receive(:setup_readme)
          allow(instance).to receive(:create_gem_dependencies)
          allow(instance).to receive(:run)

          instance.setup_configuration

          # Verifikasi directory models dibuat dengan path engine
          expect(Dir.exist?('app/models/admin')).to be true
          expect(RiderKick.configuration.models_path).to eq('app/models/admin')
        end
      end
    end
  end
end
