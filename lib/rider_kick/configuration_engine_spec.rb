# frozen_string_literal: true

require 'tmpdir'
require 'fileutils'
require 'rider_kick/configuration'

RSpec.describe RiderKick::Configuration do
  describe '#engine_name detection' do
    it 'returns nil when no engine found' do
      Dir.mktmpdir do |dir|
        Dir.chdir(dir) do
          FileUtils.mkdir_p('lib')
          config = RiderKick::Configuration.new
          expect(config.engine_name).to be_nil
        end
      end
    end

    it 'returns engine name when single engine found' do
      Dir.mktmpdir do |dir|
        Dir.chdir(dir) do
          FileUtils.mkdir_p('lib/core')
          File.write('lib/core/engine.rb', 'module Core; class Engine < ::Rails::Engine; end; end')

          config = RiderKick::Configuration.new
          expect(config.engine_name).to eq('Core')
        end
      end
    end

    it 'returns nil when multiple engines found (requires explicit specification)' do
      Dir.mktmpdir do |dir|
        Dir.chdir(dir) do
          FileUtils.mkdir_p(['lib/core', 'lib/admin'])
          File.write('lib/core/engine.rb', 'module Core; class Engine < ::Rails::Engine; end; end')
          File.write('lib/admin/engine.rb', 'module Admin; class Engine < ::Rails::Engine; end; end')

          config = RiderKick::Configuration.new
          expect(config.engine_name).to be_nil
        end
      end
    end

    it 'can be set explicitly via engine_name=' do
      Dir.mktmpdir do |dir|
        Dir.chdir(dir) do
          config = RiderKick::Configuration.new
          config.engine_name = 'Core'
          expect(config.engine_name).to eq('Core')
        end
      end
    end

    it 'sets engine_name to nil when given nil' do
      Dir.mktmpdir do |dir|
        Dir.chdir(dir) do
          config = RiderKick::Configuration.new
          config.engine_name = 'Core'
          config.engine_name = nil
          expect(config.engine_name).to be_nil
        end
      end
    end

    it 'sets engine_name to nil when given empty string' do
      Dir.mktmpdir do |dir|
        Dir.chdir(dir) do
          config = RiderKick::Configuration.new
          config.engine_name = ''
          expect(config.engine_name).to be_nil
        end
      end
    end
  end

  describe '#models_path' do
    it 'returns app/models/models when no engine' do
      Dir.mktmpdir do |dir|
        Dir.chdir(dir) do
          config = RiderKick::Configuration.new
          config.engine_name = nil
          expect(config.models_path).to eq('app/models/models')
        end
      end
    end

    it 'returns engines/<engine_name>/app/models/<engine_name>/models when engine is set' do
      Dir.mktmpdir do |dir|
        Dir.chdir(dir) do
          config = RiderKick::Configuration.new
          config.engine_name = 'Core'
          expect(config.models_path).to eq('engines/core/app/models/core/models')
        end
      end
    end

    it 'updates models_path when engine_name changes' do
      Dir.mktmpdir do |dir|
        Dir.chdir(dir) do
          config = RiderKick::Configuration.new

          config.engine_name = nil
          expect(config.models_path).to eq('app/models/models')

          config.engine_name = 'Admin'
          expect(config.models_path).to eq('engines/admin/app/models/admin/models')

          config.engine_name = nil
          expect(config.models_path).to eq('app/models/models')
        end
      end
    end
  end

  describe '#detect_engine_name' do
    it 'returns nil when lib directory does not exist' do
      Dir.mktmpdir do |dir|
        Dir.chdir(dir) do
          config = RiderKick::Configuration.new
          expect(config.engine_name).to be_nil
        end
      end
    end

    it 'detects engine from gemspec fallback when multiple engines exist' do
      Dir.mktmpdir do |dir|
        Dir.chdir(dir) do
          FileUtils.mkdir_p(['lib/core', 'lib/admin'])
          File.write('lib/core/engine.rb', 'module Core; class Engine < ::Rails::Engine; end; end')
          File.write('lib/admin/engine.rb', 'module Admin; class Engine < ::Rails::Engine; end; end')
          File.write('test-admin.gemspec', "Gem::Specification.new do |s|\n  s.name = 'test-admin'\nend")

          config = RiderKick::Configuration.new
          # Should return Admin because gemspec name matches Admin engine
          # The logic checks if gemspec name matches an existing engine
          expect(config.engine_name).to eq('Admin')
        end
      end
    end

    it 'detects engine from gemspec fallback when single matching engine' do
      Dir.mktmpdir do |dir|
        Dir.chdir(dir) do
          FileUtils.mkdir_p('lib/core')
          File.write('lib/core/engine.rb', 'module Core; class Engine < ::Rails::Engine; end; end')
          File.write('test-core.gemspec', "Gem::Specification.new do |s|\n  s.name = 'test-core'\nend")

          config = RiderKick::Configuration.new
          # Should return Core because it matches the gemspec name
          expect(config.engine_name).to eq('Core')
        end
      end
    end
  end

  describe '#detect_domains_path' do
    it 'returns app/domains/<domain_scope> when no engine' do
      Dir.mktmpdir do |dir|
        Dir.chdir(dir) do
          config = RiderKick::Configuration.new
          config.engine_name = nil
          config.domain_scope = 'admin/'
          expect(config.domains_path).to eq('app/domains/admin/')
        end
      end
    end

    it 'returns engines/<engine_name>/app/domains/<domain_scope> when engine is set' do
      Dir.mktmpdir do |dir|
        Dir.chdir(dir) do
          config = RiderKick::Configuration.new
          config.engine_name = 'Core'
          config.domain_scope = 'admin/'
          expect(config.domains_path).to eq('engines/core/app/domains/admin/')
        end
      end
    end

    it 'handles empty domain_scope' do
      Dir.mktmpdir do |dir|
        Dir.chdir(dir) do
          config = RiderKick::Configuration.new
          config.engine_name = nil
          config.domain_scope = ''
          expect(config.domains_path).to eq('app/domains/')
        end
      end
    end
  end

  describe '#domains_path=' do
    it 'updates @domains_path with expanded path' do
      Dir.mktmpdir do |dir|
        Dir.chdir(dir) do
          config = RiderKick::Configuration.new
          config.domains_path = 'custom/path'
          expect(config.domains_path).to eq(File.expand_path('custom/path'))
        end
      end
    end

    it 'updates @entities_path' do
      Dir.mktmpdir do |dir|
        Dir.chdir(dir) do
          config = RiderKick::Configuration.new
          config.domains_path = 'custom/path'
          expect(config.entities_path).to eq(File.join(File.expand_path('custom/path'), 'entities'))
        end
      end
    end

    it 'updates @adapters_path' do
      Dir.mktmpdir do |dir|
        Dir.chdir(dir) do
          config = RiderKick::Configuration.new
          config.domains_path = 'custom/path'
          expect(config.adapters_path).to eq(File.join(File.expand_path('custom/path'), 'adapters'))
        end
      end
    end
  end

  describe '#models_path=' do
    it 'updates @models_path with expanded path' do
      Dir.mktmpdir do |dir|
        Dir.chdir(dir) do
          config = RiderKick::Configuration.new
          config.models_path = 'custom/models'
          expect(config.models_path).to eq(File.expand_path('custom/models'))
        end
      end
    end
  end

  describe '#engine_name=' do
    it 'updates paths when engine_name is set' do
      Dir.mktmpdir do |dir|
        Dir.chdir(dir) do
          config = RiderKick::Configuration.new
          config.engine_name = 'Core'
          expect(config.models_path).to eq('engines/core/app/models/core/models')
          expect(config.domains_path).to eq('engines/core/app/domains/')
        end
      end
    end

    it 'updates entities_path and adapters_path when engine_name is set' do
      Dir.mktmpdir do |dir|
        Dir.chdir(dir) do
          config = RiderKick::Configuration.new
          config.engine_name = 'Core'
          expect(config.entities_path).to eq('engines/core/app/domains/entities')
          expect(config.adapters_path).to eq('engines/core/app/domains/adapters')
        end
      end
    end

    it 'handles nil' do
      Dir.mktmpdir do |dir|
        Dir.chdir(dir) do
          config = RiderKick::Configuration.new
          config.engine_name = 'Core'
          config.engine_name = nil
          expect(config.engine_name).to be_nil
          expect(config.models_path).to eq('app/models/models')
        end
      end
    end

    it 'handles empty string' do
      Dir.mktmpdir do |dir|
        Dir.chdir(dir) do
          config = RiderKick::Configuration.new
          config.engine_name = 'Core'
          config.engine_name = ''
          expect(config.engine_name).to be_nil
        end
      end
    end

    it 'handles whitespace-only string' do
      Dir.mktmpdir do |dir|
        Dir.chdir(dir) do
          config = RiderKick::Configuration.new
          config.engine_name = '   '
          expect(config.engine_name).to be_nil
        end
      end
    end
  end

  describe '#domain_scope=' do
    it 'updates domains_path when domain_scope is set' do
      Dir.mktmpdir do |dir|
        Dir.chdir(dir) do
          config = RiderKick::Configuration.new
          config.domain_scope = 'admin/'
          expect(config.domains_path).to eq('app/domains/admin/')
        end
      end
    end

    it 'updates entities_path and adapters_path when domain_scope is set' do
      Dir.mktmpdir do |dir|
        Dir.chdir(dir) do
          config = RiderKick::Configuration.new
          config.domain_scope = 'admin/'
          expect(config.entities_path).to eq('app/domains/admin/entities')
          expect(config.adapters_path).to eq('app/domains/admin/adapters')
        end
      end
    end

    it 'handles nil' do
      Dir.mktmpdir do |dir|
        Dir.chdir(dir) do
          config = RiderKick::Configuration.new
          config.domain_scope = 'admin/'
          config.domain_scope = nil
          expect(config.domain_scope).to eq('')
        end
      end
    end

    it 'handles empty string' do
      Dir.mktmpdir do |dir|
        Dir.chdir(dir) do
          config = RiderKick::Configuration.new
          config.domain_scope = 'admin/'
          config.domain_scope = ''
          expect(config.domain_scope).to eq('')
        end
      end
    end

    it 'handles whitespace-only string' do
      Dir.mktmpdir do |dir|
        Dir.chdir(dir) do
          config = RiderKick::Configuration.new
          config.domain_scope = '   '
          expect(config.domain_scope).to eq('')
        end
      end
    end

    it 'updates paths correctly with engine and domain_scope' do
      Dir.mktmpdir do |dir|
        Dir.chdir(dir) do
          config = RiderKick::Configuration.new
          config.engine_name = 'Core'
          config.domain_scope = 'admin/'
          expect(config.domains_path).to eq('engines/core/app/domains/admin/')
          expect(config.entities_path).to eq('engines/core/app/domains/admin/entities')
          expect(config.adapters_path).to eq('engines/core/app/domains/admin/adapters')
        end
      end
    end
  end

  describe 'RiderKick.configuration' do
    it 'returns singleton Configuration instance' do
      config1 = RiderKick.configuration
      config2 = RiderKick.configuration
      expect(config1.object_id).to eq(config2.object_id)
    end
  end

  describe 'RiderKick.configure' do
    it 'yields configuration instance' do
      RiderKick.configure do |config|
        expect(config).to be_a(RiderKick::Configuration)
        config.engine_name = 'TestEngine'
        expect(config.engine_name).to eq('TestEngine')
      end
    end
  end
end
