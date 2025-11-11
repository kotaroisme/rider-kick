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
end
