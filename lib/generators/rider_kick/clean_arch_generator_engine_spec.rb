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

  context 'domain scope default behavior' do
    it 'uses empty domain scope as default' do
      Dir.mktmpdir do |dir|
        Dir.chdir(dir) do
          # Reset configuration to defaults
          RiderKick.configuration.engine_name = nil
          RiderKick.configuration.domain_scope = ''

          # Mock the domain_class_name method to return predictable result
          generator = klass.new([])
          allow(generator).to receive(:domain_class_name).and_return('MyApp')

          expect(RiderKick.configuration.domain_scope).to eq('')
          expect(RiderKick.configuration.domains_path).to eq('app/domains/')
        end
      end
    end

    it 'generates class names with app name for empty domain scope in main app' do
      Dir.mktmpdir do |dir|
        Dir.chdir(dir) do
          # Create minimal Rails app structure for testing
          FileUtils.mkdir_p('app/domains')

          # Reset configuration
          RiderKick.configuration.engine_name = nil
          RiderKick.configuration.domain_scope = ''

          instance = klass.new([])
          opts = double('options', setup: true)
          allow(opts).to receive(:[]).and_return(nil)
          allow(opts).to receive(:[]).with(:engine).and_return(nil)
          allow(opts).to receive(:[]).with(:quiet).and_return(false)
          allow(instance).to receive(:options).and_return(opts)

          # Mock methods to avoid actual file generation
          allow(instance).to receive(:setup_domain_structure)
          allow(instance).to receive(:setup_initializers)
          allow(instance).to receive(:setup_dotenv)
          allow(instance).to receive(:setup_gitignore)
          allow(instance).to receive(:setup_rubocop)
          allow(instance).to receive(:setup_active_storage)
          allow(instance).to receive(:setup_rspec)
          allow(instance).to receive(:setup_readme)
          allow(instance).to receive(:create_gem_dependencies)
          allow(instance).to receive(:setup_init_migration)
          allow(instance).to receive(:setup_models)
          allow(instance).to receive(:say)

          # Test domain_class_name method
          expect(instance.send(:domain_class_name)).to eq('MyApp')

          # Test configuration paths
          expect(RiderKick.configuration.domains_path).to eq('app/domains/')
          expect(RiderKick.configuration.models_path).to eq('app/models/models')
        end
      end
    end

    it 'generates class names with engine name for empty domain scope in engine' do
      Dir.mktmpdir do |dir|
        Dir.chdir(dir) do
          # Create minimal engine structure for testing
          FileUtils.mkdir_p('engines/admin/lib/admin/engine.rb')

          # Reset configuration
          RiderKick.configuration.engine_name = 'Admin'
          RiderKick.configuration.domain_scope = ''

          instance = klass.new([])
          opts = double('options', setup: true)
          allow(opts).to receive(:[]).and_return(nil)
          allow(opts).to receive(:[]).with(:engine).and_return('Admin')
          allow(opts).to receive(:[]).with(:quiet).and_return(false)
          allow(instance).to receive(:options).and_return(opts)

          # Mock methods to avoid actual file generation
          allow(instance).to receive(:setup_domain_structure)
          allow(instance).to receive(:setup_initializers)
          allow(instance).to receive(:setup_dotenv)
          allow(instance).to receive(:setup_gitignore)
          allow(instance).to receive(:setup_rubocop)
          allow(instance).to receive(:setup_active_storage)
          allow(instance).to receive(:setup_rspec)
          allow(instance).to receive(:setup_readme)
          allow(instance).to receive(:create_gem_dependencies)
          allow(instance).to receive(:setup_init_migration)
          allow(instance).to receive(:setup_models)
          allow(instance).to receive(:say)

          # Test domain_class_name method for engine
          expect(instance.send(:domain_class_name)).to eq('Admin')

          # Test configuration paths
          expect(RiderKick.configuration.domains_path).to eq('engines/admin/app/domains/')
          expect(RiderKick.configuration.models_path).to eq('app/models/admin')
        end
      end
    end

    it 'generates class names with engine and domain for scoped domain in engine' do
      Dir.mktmpdir do |dir|
        Dir.chdir(dir) do
          # Create minimal engine structure for testing
          FileUtils.mkdir_p('engines/admin/lib/admin/engine.rb')

          # Reset configuration
          RiderKick.configuration.engine_name = 'Admin'
          RiderKick.configuration.domain_scope = 'core/'

          instance = klass.new([])
          opts = double('options', setup: true)
          allow(opts).to receive(:[]).and_return(nil)
          allow(opts).to receive(:[]).with(:engine).and_return('Admin')
          allow(opts).to receive(:[]).with(:domain).and_return('core/')
          allow(opts).to receive(:[]).with(:quiet).and_return(false)
          allow(instance).to receive(:options).and_return(opts)

          # Mock methods to avoid actual file generation
          allow(instance).to receive(:setup_domain_structure)
          allow(instance).to receive(:setup_initializers)
          allow(instance).to receive(:setup_dotenv)
          allow(instance).to receive(:setup_gitignore)
          allow(instance).to receive(:setup_rubocop)
          allow(instance).to receive(:setup_active_storage)
          allow(instance).to receive(:setup_rspec)
          allow(instance).to receive(:setup_readme)
          allow(instance).to receive(:create_gem_dependencies)
          allow(instance).to receive(:setup_init_migration)
          allow(instance).to receive(:setup_models)
          allow(instance).to receive(:say)

          # Test domain_class_name method for engine with domain
          expect(instance.send(:domain_class_name)).to eq('Admin::Core')

          # Test domain_class_name_for_application_record method
          expect(instance.send(:domain_class_name_for_application_record)).to eq('Admin')

          # Test configuration paths - when both engine and domain specified, structure goes to engine domains
          expect(RiderKick.configuration.domains_path).to eq('engines/admin/app/domains/core/')
          expect(RiderKick.configuration.models_path).to eq('app/models/admin')
        end
      end
    end

    it 'creates domains structure in engine when both engine and domain are specified during setup' do
      Dir.mktmpdir do |dir|
        Dir.chdir(dir) do
          # Create minimal Rails app structure for testing
          FileUtils.mkdir_p('app/domains')

          # Reset configuration
          RiderKick.configuration.engine_name = 'MyEngine'
          RiderKick.configuration.domain_scope = 'admin/'

          instance = klass.new([])
          opts = double('options', setup: true)
          allow(opts).to receive(:[]).and_return(nil)
          allow(opts).to receive(:[]).with(:engine).and_return('MyEngine')
          allow(opts).to receive(:[]).with(:domain).and_return('admin/')
          allow(opts).to receive(:[]).with(:quiet).and_return(false)
          allow(instance).to receive(:options).and_return(opts)

          # Mock methods to avoid actual file generation
          allow(instance).to receive(:setup_domain_structure)
          allow(instance).to receive(:setup_initializers)
          allow(instance).to receive(:setup_dotenv)
          allow(instance).to receive(:setup_gitignore)
          allow(instance).to receive(:setup_rubocop)
          allow(instance).to receive(:setup_active_storage)
          allow(instance).to receive(:setup_rspec)
          allow(instance).to receive(:setup_readme)
          allow(instance).to receive(:create_gem_dependencies)
          allow(instance).to receive(:setup_init_migration)
          allow(instance).to receive(:setup_models)
          allow(instance).to receive(:say)

          # Test domain_class_name method for engine with domain
          expect(instance.send(:domain_class_name)).to eq('MyEngine::Admin')

          # Test configuration paths - should create structure in engine domains
          expect(RiderKick.configuration.domains_path).to eq('engines/my_engine/app/domains/admin/')
          expect(RiderKick.configuration.models_path).to eq('app/models/my_engine')
        end
      end
    end

    it 'generates ApplicationRecord class name for main app' do
      Dir.mktmpdir do |dir|
        Dir.chdir(dir) do
          # Create minimal Rails app structure for testing
          FileUtils.mkdir_p('app/domains')

          # Reset configuration
          RiderKick.configuration.engine_name = nil
          RiderKick.configuration.domain_scope = ''

          instance = klass.new([])
          opts = double('options', setup: true)
          allow(opts).to receive(:[]).and_return(nil)
          allow(opts).to receive(:[]).with(:engine).and_return(nil)
          allow(opts).to receive(:[]).with(:quiet).and_return(false)
          allow(instance).to receive(:options).and_return(opts)

          # Mock methods to avoid actual file generation
          allow(instance).to receive(:setup_domain_structure)
          allow(instance).to receive(:setup_initializers)
          allow(instance).to receive(:setup_dotenv)
          allow(instance).to receive(:setup_gitignore)
          allow(instance).to receive(:setup_rubocop)
          allow(instance).to receive(:setup_active_storage)
          allow(instance).to receive(:setup_rspec)
          allow(instance).to receive(:setup_readme)
          allow(instance).to receive(:create_gem_dependencies)
          allow(instance).to receive(:setup_init_migration)
          allow(instance).to receive(:setup_models)
          allow(instance).to receive(:say)

          # Test domain_class_name_for_application_record method for main app
          expect(instance.send(:domain_class_name_for_application_record)).to eq('')

          # Test configuration paths
          expect(RiderKick.configuration.domains_path).to eq('app/domains/')
          expect(RiderKick.configuration.models_path).to eq('app/models/models')
        end
      end
    end
  end
end
