# frozen_string_literal: true

require 'rails/generators'
require 'tmpdir'
require 'fileutils'
require 'generators/rider_kick/structure_generator'

RSpec.describe 'rider_kick:structure generator with engine and domain options' do
  let(:klass) { RiderKick::Structure }

  context 'with --domain option' do
    it 'uses domain scope for configuration' do
      Dir.mktmpdir do |dir|
        Dir.chdir(dir) do
          # Set domain scope
          RiderKick.configuration.domain_scope = 'admin/'

          FileUtils.mkdir_p(RiderKick.configuration.domains_path)
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
                Column.new('email', :string),
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

          # Test dengan domain admin
          instance = klass.new(['Models::User', 'actor:admin', 'resource_owner:account', 'resource_owner_id:account_id'])
          allow(instance).to receive(:options).and_return({ domain: 'admin/' })
          instance.generate_use_case

          # Verifikasi domain scope sudah di-set
          expect(RiderKick.configuration.domain_scope).to eq('admin/')
          expect(RiderKick.configuration.domains_path).to eq('app/domains/admin/')
          expect(File).to exist('db/structures/users_structure.yaml')
        end
      end
    end

    it 'generates structure file with domain scope api/v1/' do
      Dir.mktmpdir do |dir|
        Dir.chdir(dir) do
          # Set domain scope
          RiderKick.configuration.domain_scope = 'api/v1/'

          FileUtils.mkdir_p(RiderKick.configuration.domains_path)
          FileUtils.mkdir_p('app/models/models')

          # Stub model classes
          Object.send(:remove_const, :Models) if Object.const_defined?(:Models)
          Object.send(:remove_const, :Column) if Object.const_defined?(:Column)
          module Models; end

          Column = Struct.new(:name, :type, :sql_type, :null, :default, :precision, :scale, :limit)
          class Models::Article
            def self.columns
              [
                Column.new('id', :uuid),
                Column.new('title', :string),
                Column.new('content', :text),
                Column.new('published', :boolean),
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

          # Test dengan domain api/v1
          instance = klass.new(['Models::Article', 'actor:user', 'resource_owner:account', 'resource_owner_id:account_id'])
          allow(instance).to receive(:options).and_return({ domain: 'api/v1/' })
          instance.generate_use_case

          # Verifikasi domain scope sudah di-set
          expect(RiderKick.configuration.domain_scope).to eq('api/v1/')
          expect(RiderKick.configuration.domains_path).to eq('app/domains/api/v1/')
          expect(File).to exist('db/structures/articles_structure.yaml')
        end
      end
    end
  end

  context 'without --engine option (main app)' do
    it 'uses main app models path when no engine specified' do
      Dir.mktmpdir do |dir|
        Dir.chdir(dir) do
          FileUtils.mkdir_p(RiderKick.configuration.domains_path)
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

          instance = klass.new(['Models::User', 'actor:owner', 'resource_owner:account', 'resource_owner_id:account_id'])
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
          # Set configuration for test first
          RiderKick.configuration.engine_name = 'Core'
          RiderKick.configuration.domain_scope = 'core/'

          FileUtils.mkdir_p(RiderKick.configuration.domains_path)
          FileUtils.mkdir_p(RiderKick.configuration.models_path)
          engine_structures_path = "engines/#{RiderKick.configuration.engine_name.downcase}/db/structures"
          FileUtils.mkdir_p(engine_structures_path)

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

          instance = klass.new(['Models::Core::User', 'actor:owner', 'resource_owner:account', 'resource_owner_id:account_id'])
          instance.generate_use_case

          # Verifikasi models_path menggunakan engine
          expect(RiderKick.configuration.models_path).to eq('engines/core/app/models/core/models')
          expect(RiderKick.configuration.engine_name).to eq('Core')
          expect(File).to exist('engines/core/db/structures/users_structure.yaml')
        end
      end
    end

    it 'generates structure file with correct engine configuration' do
      Dir.mktmpdir do |dir|
        Dir.chdir(dir) do
          # Set configuration for test first
          RiderKick.configuration.engine_name = 'Admin'
          RiderKick.configuration.domain_scope = 'core/'

          FileUtils.mkdir_p(RiderKick.configuration.domains_path)
          FileUtils.mkdir_p(RiderKick.configuration.models_path)
          engine_structures_path = "engines/#{RiderKick.configuration.engine_name.downcase}/db/structures"
          FileUtils.mkdir_p(engine_structures_path)

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

          instance = klass.new(['Models::Admin::Product', 'actor:admin', 'resource_owner:account', 'resource_owner_id:account_id'])
          instance.generate_use_case

          # Verifikasi engine name sudah di-set
          expect(RiderKick.configuration.engine_name).to eq('Admin')
          expect(RiderKick.configuration.models_path).to eq('engines/admin/app/models/admin/models')

          # Verifikasi file structure ter-generate
          expect(File).to exist('engines/admin/db/structures/products_structure.yaml')
          yaml = File.read('engines/admin/db/structures/products_structure.yaml')
          expect(yaml).to include('model: Models::Admin::Product')
        end
      end
    end

    it 'mengangkat Thor::Error jika engine domains belum ada' do
      Dir.mktmpdir do |dir|
        Dir.chdir(dir) do
          instance = klass.new(['Models::OrderEngine::Order', 'actor:user', 'resource_owner:account', 'resource_owner_id:account_id'])
          allow(instance).to receive(:options).and_return({ engine: 'OrderEngine', domain: 'fulfillment/' })

          expect {
            instance.generate_use_case
          }.to raise_error(Thor::Error, /clean_arch.*--setup/i)
        end
      end
    end
  end
end
