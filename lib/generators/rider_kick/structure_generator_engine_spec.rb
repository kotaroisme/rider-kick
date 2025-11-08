# frozen_string_literal: true

require 'rails/generators'
require 'tmpdir'
require 'fileutils'
require 'generators/rider_kick/structure_generator'

RSpec.describe 'rider_kick:structure generator with engine option' do
  let(:klass) { RiderKick::Structure }

  context 'without --engine option (main app)' do
    it 'uses main app models path when no engine specified' do
      Dir.mktmpdir do |dir|
        Dir.chdir(dir) do
          FileUtils.mkdir_p(RiderKick.configuration.domains_path + '/core/use_cases')
          FileUtils.mkdir_p('app/models/models')

          # Stub model classes
          Object.send(:remove_const, :Models) if Object.const_defined?(:Models)
          Object.send(:remove_const, :Column) if Object.const_defined?(:Column)
          module Models; end

          Column = Struct.new(:name, :type, :sql_type, :null, :default, :precision, :scale, :limit)
          class Models::User
            def self.columns
              [
                Column.new('id', :uuid),
                Column.new('name', :string),
                Column.new('price', :decimal),
                Column.new('created_at', :datetime),
                Column.new('updated_at', :datetime)
              ]
            end

            def self.columns_hash
              columns.to_h { |c| [c.name.to_s, Struct.new(:type).new(c.type)] }
            end

            def self.column_names
              columns.map { |c| c.name.to_s }
            end
          end

          # Reset configuration untuk test
          RiderKick.configuration.engine_name = nil

          instance = klass.new(['Models::User', 'actor:owner'])
          allow(instance).to receive(:options).and_return({ engine: nil })
          instance.generate_use_case

          # Verifikasi models_path menggunakan main app
          expect(RiderKick.configuration.models_path).to eq('app/models/models')
          expect(RiderKick.configuration.engine_name).to be_nil
          expect(File).to exist('db/structures/users_structure.yaml')
        end
      end
    end
  end

  context 'with --engine option' do
    it 'uses engine models path when engine specified' do
      Dir.mktmpdir do |dir|
        Dir.chdir(dir) do
          FileUtils.mkdir_p(RiderKick.configuration.domains_path + '/core/use_cases')
          FileUtils.mkdir_p('app/models/core')

          # Stub model classes
          Object.send(:remove_const, :Models) if Object.const_defined?(:Models)
          Object.send(:remove_const, :Column) if Object.const_defined?(:Column)
          module Models; end

          module Models::Core; end

          Column = Struct.new(:name, :type, :sql_type, :null, :default, :precision, :scale, :limit)
          class Models::Core::User
            def self.columns
              [
                Column.new('id', :uuid),
                Column.new('name', :string),
                Column.new('price', :decimal),
                Column.new('created_at', :datetime),
                Column.new('updated_at', :datetime)
              ]
            end

            def self.columns_hash
              columns.to_h { |c| [c.name.to_s, Struct.new(:type).new(c.type)] }
            end

            def self.column_names
              columns.map { |c| c.name.to_s }
            end
          end

          # Reset configuration untuk test
          RiderKick.configuration.engine_name = nil

          instance = klass.new(['Models::Core::User', 'actor:owner'])
          allow(instance).to receive(:options).and_return({ engine: 'Core' })
          instance.generate_use_case

          # Verifikasi models_path menggunakan engine
          expect(RiderKick.configuration.models_path).to eq('app/models/core')
          expect(RiderKick.configuration.engine_name).to eq('Core')
          expect(File).to exist('db/structures/users_structure.yaml')
        end
      end
    end

    it 'generates structure file with correct engine configuration' do
      Dir.mktmpdir do |dir|
        Dir.chdir(dir) do
          FileUtils.mkdir_p(RiderKick.configuration.domains_path + '/core/use_cases')
          FileUtils.mkdir_p('app/models/admin')

          # Stub model classes
          Object.send(:remove_const, :Models) if Object.const_defined?(:Models)
          Object.send(:remove_const, :Column) if Object.const_defined?(:Column)
          module Models; end

          module Models::Admin; end

          Column = Struct.new(:name, :type, :sql_type, :null, :default, :precision, :scale, :limit)
          class Models::Admin::Product
            def self.columns
              [
                Column.new('id', :uuid),
                Column.new('name', :string),
                Column.new('price', :decimal),
                Column.new('created_at', :datetime),
                Column.new('updated_at', :datetime)
              ]
            end

            def self.columns_hash
              columns.to_h { |c| [c.name.to_s, Struct.new(:type).new(c.type)] }
            end

            def self.column_names
              columns.map { |c| c.name.to_s }
            end
          end

          # Reset configuration untuk test
          RiderKick.configuration.engine_name = nil

          instance = klass.new(['Models::Admin::Product', 'actor:admin'])
          allow(instance).to receive(:options).and_return({ engine: 'Admin' })
          instance.generate_use_case

          # Verifikasi engine name sudah di-set
          expect(RiderKick.configuration.engine_name).to eq('Admin')
          expect(RiderKick.configuration.models_path).to eq('app/models/admin')

          # Verifikasi file structure ter-generate
          expect(File).to exist('db/structures/products_structure.yaml')
          yaml = File.read('db/structures/products_structure.yaml')
          expect(yaml).to include('model: Models::Admin::Product')
        end
      end
    end
  end
end
