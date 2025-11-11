# frozen_string_literal: true

require 'rails/generators'
require 'tmpdir'
require 'fileutils'
require 'generators/rider_kick/scaffold_generator'

RSpec.describe 'rider_kick:scaffold generator with engine option' do
  let(:klass) { RiderKick::ScaffoldGenerator }

  context 'without --engine option (main app)' do
    it 'uses main app models path (app/models/models)' do
      Dir.mktmpdir do |dir|
        Dir.chdir(dir) do
          FileUtils.mkdir_p([
                              RiderKick.configuration.domains_path + '/core/use_cases',
                              RiderKick.configuration.domains_path + '/core/repositories',
                              RiderKick.configuration.domains_path + '/core/builders',
                              RiderKick.configuration.domains_path + '/core/entities',
                              'app/models/models',
                              'db/structures'
                            ])

          File.write('app/models/models/user.rb', "class Models::User < ApplicationRecord; end\n")
          File.write('db/structures/users_structure.yaml', <<~YAML)
            model: Models::User
            resource_name: users
            actor: owner
            resource_owner_id: account_id
            resource_owner: account
            uploaders: []
            search_able: []
            domains:
              action_list:        { use_case: { contract: [] } }
              action_fetch_by_id: { use_case: { contract: [] } }
              action_create:      { use_case: { contract: [] } }
              action_update:      { use_case: { contract: [] } }
              action_destroy:     { use_case: { contract: [] } }
            entity: { db_attributes: [id, created_at, updated_at] }
          YAML

          # Reset configuration untuk test
          RiderKick.configuration.engine_name = nil

          instance = klass.new(['users'])
          allow(instance).to receive(:options).and_return({ engine: nil })
          instance.generate_use_case

          # Verifikasi models_path menggunakan main app
          expect(RiderKick.configuration.models_path).to eq('app/models/models')
          expect(RiderKick.configuration.engine_name).to be_nil
        end
      end
    end
  end

  context 'with --engine option' do
    it 'uses engine models path (engines/<engine_name>/app/models/<engine_name>/models)' do
      Dir.mktmpdir do |dir|
        Dir.chdir(dir) do
          # Set configuration for test first
          RiderKick.configuration.engine_name = 'Core'
          RiderKick.configuration.domain_scope = 'core/'

          FileUtils.mkdir_p([
                              RiderKick.configuration.domains_path,
                              RiderKick.configuration.models_path,
                              'engines/core/app/models/core',
                              'db/structures'
                            ])

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

          File.write('engines/core/app/models/core/models/user.rb', "class Models::Core::User < ApplicationRecord; end\n")
          File.write('db/structures/users_structure.yaml', <<~YAML)
            model: Models::Core::User
            resource_name: users
            actor: owner
            resource_owner_id: account_id
            resource_owner: account
            uploaders: []
            search_able: []
            domains:
              action_list:        { use_case: { contract: [] } }
              action_fetch_by_id: { use_case: { contract: [] } }
              action_create:      { use_case: { contract: [] } }
              action_update:      { use_case: { contract: [] } }
              action_destroy:     { use_case: { contract: [] } }
            entity: { db_attributes: [id, created_at, updated_at] }
          YAML

          instance = klass.new(['users'])
          instance.generate_use_case

          # Verifikasi models_path menggunakan engine
          expect(RiderKick.configuration.models_path).to eq('engines/core/app/models/core/models')
          expect(RiderKick.configuration.engine_name).to eq('Core')
        end
      end
    end

    it 'generates files with correct engine configuration' do
      Dir.mktmpdir do |dir|
        Dir.chdir(dir) do
          # Set configuration for test first
          RiderKick.configuration.engine_name = 'Admin'
          RiderKick.configuration.domain_scope = 'admin/core/' # Engine-prefixed

          FileUtils.mkdir_p([
                              RiderKick.configuration.domains_path,
                              'app/models/admin',
                              'db/structures'
                            ])

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

          File.write('app/models/admin/product.rb', "class Models::Admin::Product < ApplicationRecord; end\n")
          File.write('db/structures/products_structure.yaml', <<~YAML)
            model: Models::Admin::Product
            resource_name: products
            actor: admin
            resource_owner_id: account_id
            resource_owner: account
            uploaders: []
            search_able: []
            domains:
              action_list:        { use_case: { contract: [] } }
              action_fetch_by_id: { use_case: { contract: [] } }
              action_create:      { use_case: { contract: [] } }
              action_update:      { use_case: { contract: [] } }
              action_destroy:     { use_case: { contract: [] } }
            entity: { db_attributes: [id, created_at, updated_at] }
          YAML

          instance = klass.new(['products'])
          instance.generate_use_case

          # Verifikasi engine name sudah di-set
          expect(RiderKick.configuration.engine_name).to eq('Admin')
          expect(RiderKick.configuration.models_path).to eq('engines/admin/app/models/admin/models')

          # Verifikasi files ter-generate
          expect(File).to exist(RiderKick.configuration.domains_path + '/builders/product.rb')
          expect(File).to exist(RiderKick.configuration.domains_path + '/entities/product.rb')
        end
      end
    end
  end
end
