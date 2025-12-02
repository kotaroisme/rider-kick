# frozen_string_literal: true

require 'rails/generators'
require 'tmpdir'
require 'active_support/inflector'

require 'fileutils'
require 'generators/rider_kick/scaffold_generator'

RSpec.describe 'rider_kick:scaffold generator (RSpec generation)' do
  let(:klass) { RiderKick::ScaffoldGenerator }

  it 'menghasilkan spec files untuk use_cases, repositories, builder, dan entity' do
    Dir.mktmpdir do |dir|
      Dir.chdir(dir) do
        # 1) siapkan kerangka clean-arch minimal
        FileUtils.mkdir_p(RiderKick.configuration.domains_path)
        FileUtils.mkdir_p('app/models/models')
        FileUtils.mkdir_p('spec/models/models')
        FileUtils.mkdir_p('db/structures')

        # 2) stub namespace & model + metadata kolom
        Object.send(:remove_const, :Models) if Object.const_defined?(:Models)
        Object.send(:remove_const, :Column) if Object.const_defined?(:Column)
        module Models; end

        Column = Struct.new(:name, :type, :sql_type, :null, :default, :precision, :scale, :limit)
        class Models::Product
          def self.columns
            [
              Column.new('id', :uuid, nil, false, nil, nil, nil, nil),
              Column.new('name', :string, nil, false, nil, nil, nil, 255),
              Column.new('price', :decimal, nil, false, nil, 10, 2, nil),
              Column.new('description', :text, nil, true, nil, nil, nil, nil),
              Column.new('created_at', :datetime, nil, false, nil, nil, nil, nil),
              Column.new('updated_at', :datetime, nil, false, nil, nil, nil, nil)
            ]
          end

          def self.columns_hash
            columns.to_h { |c| [c.name.to_s, Struct.new(:type).new(c.type)] }
          end

          def self.column_names
            columns.map { |c| c.name.to_s }
          end
        end

        # 3) file model untuk inject
        File.write('app/models/models/product.rb', <<~RUBY)
          class Models::Product < ApplicationRecord
          end
        RUBY

        # 4) YAML struktur dengan uploaders
        File.write('db/structures/products_structure.yaml', <<~YAML)
          model: Models::Product
          resource_name: products
          actor: user
          resource_owner_id: account_id
          resource_owner: account
          uploaders:
            - { name: 'image', type: 'single' }
            - { name: 'documents', type: 'multiple' }
          search_able: []
          domains:
            action_list:
              use_case:
                contract: []
              repository:
                filters: []
            action_fetch_by_id:
              use_case:
                contract:
                  - "required(:id).filled(:string)"
            action_create:
              use_case:
                contract:
                  - "required(:name).filled(:string)"
                  - "required(:price).filled(:decimal)"
            action_update:
              use_case:
                contract:
                  - "optional(:name).maybe(:string)"
                  - "optional(:price).maybe(:decimal)"
            action_destroy:
              use_case:
                contract: []
          entity:
            db_attributes:
              - name
              - price
              - description
        YAML

        # 5) jalankan generator
        instance = klass.new(['products'])
        instance.generate_use_case

        # 6) verifikasi artefak code files
        ['user_create_product', 'user_update_product', 'user_list_product', 'user_destroy_product', 'user_fetch_product_by_id'].each do |uc|
          expect(File).to exist(File.join(RiderKick.configuration.domains_path + '/use_cases/products', "#{uc}.rb")), "Expected use case file #{uc}.rb to exist"
        end

        ['create_product', 'update_product', 'list_product', 'destroy_product', 'fetch_product_by_id'].each do |repo|
          expect(File).to exist(File.join(RiderKick.configuration.domains_path + '/repositories/products', "#{repo}.rb")), "Expected repository file #{repo}.rb to exist"
        end

        expect(File).to exist(RiderKick.configuration.domains_path + '/builders/product.rb'), 'Expected builder file to exist'
        expect(File).to exist(RiderKick.configuration.domains_path + '/entities/product.rb'), 'Expected entity file to exist'

        # 7) VERIFIKASI SPEC FILES - INI YANG BARU!

        # Use case specs
        ['user_create_product', 'user_update_product', 'user_list_product', 'user_destroy_product', 'user_fetch_product_by_id'].each do |uc|
          spec_file = File.join(RiderKick.configuration.domains_path + '/use_cases/products', "#{uc}_spec.rb")
          expect(File).to exist(spec_file), "Expected use case spec file #{uc}_spec.rb to exist"

          # Verifikasi konten spec file
          spec_content = File.read(spec_file)
          expect(spec_content).to include('require \'rails_helper\'')
          expect(spec_content).to include('RSpec.describe')
          expect(spec_content).to include('describe \'#call\'')
          expect(spec_content).to include('context \'when parameters are valid\'')
        end

        # Repository specs
        ['create_product', 'update_product', 'list_product', 'destroy_product', 'fetch_product_by_id'].each do |repo|
          spec_file = File.join(RiderKick.configuration.domains_path + '/repositories/products', "#{repo}_spec.rb")
          expect(File).to exist(spec_file), "Expected repository spec file #{repo}_spec.rb to exist"

          # Verifikasi konten spec file
          spec_content = File.read(spec_file)
          expect(spec_content).to include('require \'rails_helper\'')
          expect(spec_content).to include('RSpec.describe')
          expect(spec_content).to include('describe \'#call\'')

          # Only check Hashie::Mash for create, update, destroy, fetch_by_id (list uses simple hash)
          if ['create_product', 'update_product', 'destroy_product', 'fetch_product_by_id'].include?(repo)
            expect(spec_content).to include('Hashie::Mash.new')
          end

          # Verify error mocking for create, update, destroy (but not list or fetch_by_id)
          if ['create_product', 'update_product', 'destroy_product'].include?(repo)
            expect(spec_content).to include('let(:error_messages)')
            expect(spec_content).to include('let(:active_model_errors)')
            expect(spec_content).to include('allow(errors).to receive(:each)')
            expect(spec_content).to include('double(as_json:')
            expect(spec_content).to include("'options' => { 'message' => 'must be valid format' }")
          end
        end

        # Builder spec (covers entity validation too)
        builder_spec = RiderKick.configuration.domains_path + '/builders/product_spec.rb'
        expect(File).to exist(builder_spec), 'Expected builder spec file to exist'

        # Model spec (sekarang sejajar dengan model di app/models/models/)
        model_spec = 'app/models/models/product_spec.rb'
        expect(File).to exist(model_spec), 'Expected model spec file to exist'

        model_spec_content = File.read(model_spec)
        expect(model_spec_content).to include('require \'rails_helper\'')
        expect(model_spec_content).to include('RSpec.describe Models::Product')
        expect(model_spec_content).to include('describe \'Active Storage attachments\'')
        expect(model_spec_content).to include('image') # single uploader
        expect(model_spec_content).to include('documents') # multiple uploader
        expect(model_spec_content).to include('has one image attached')
        expect(model_spec_content).to include('has many documents attached')
        expect(model_spec_content).to include('describe \'database columns\'')

        builder_spec_content = File.read(builder_spec)
        expect(builder_spec_content).to include('require \'rails_helper\'')
        expect(builder_spec_content).to include('RSpec.describe Core::Builders::Product')
        expect(builder_spec_content).to include('describe \'#build\'')
        expect(builder_spec_content).to include('image') # uploader single
        expect(builder_spec_content).to include('documents') # uploader multiple

        # Verify builder spec includes comprehensive entity validation tests
        expect(builder_spec_content).to include('includes all required entity attributes')
        expect(builder_spec_content).to include('describe \'#attributes_for_entity\'') # uploader method test
        expect(builder_spec_content).to include('ensures all entity attributes have correct keys and types')
        expect(builder_spec_content).to include('validates entity type schema definitions') # Dry::Types schema validation
      end
    end
  end

  it 'menghasilkan spec files dengan resource_owner_id' do
    Dir.mktmpdir do |dir|
      Dir.chdir(dir) do
        # Setup
        FileUtils.mkdir_p(RiderKick.configuration.domains_path)
        FileUtils.mkdir_p('app/models/models')
        FileUtils.mkdir_p('db/structures')

        # Stub model
        Object.send(:remove_const, :Models) if Object.const_defined?(:Models)
        Object.send(:remove_const, :Column) if Object.const_defined?(:Column)
        module Models; end

        Column = Struct.new(:name, :type, :sql_type, :null, :default, :precision, :scale, :limit)
        class Models::Task
          def self.columns
            [
              Column.new('id', :uuid),
              Column.new('account_id', :string),
              Column.new('title', :string),
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

        File.write('app/models/models/task.rb', <<~RUBY)
          class Models::Task < ApplicationRecord
          end
        RUBY

        File.write('db/structures/tasks_structure.yaml', <<~YAML)
          model: Models::Task
          resource_name: tasks
          actor: user
          resource_owner_id: account_id
          resource_owner: account
          uploaders: []
          search_able: []
          domains:
            action_list:
              use_case:
                contract: []
              repository:
                filters: []
            action_fetch_by_id:
              use_case:
                contract:
                  - "required(:id).filled(:string)"
                  - "required(:account_id).filled(:string)"
            action_create:
              use_case:
                contract:
                  - "required(:account_id).filled(:string)"
                  - "required(:title).filled(:string)"
            action_update:
              use_case:
                contract:
                  - "required(:account_id).filled(:string)"
                  - "optional(:title).maybe(:string)"
            action_destroy:
              use_case:
                contract:
                  - "required(:account_id).filled(:string)"
          entity:
            db_attributes:
              - account_id
              - title
        YAML

        # Run generator
        instance = klass.new(['tasks'])
        instance.generate_use_case

        # Verifikasi spec files include resource_owner_id
        spec_file = File.join(RiderKick.configuration.domains_path + '/use_cases/tasks', 'user_create_task_spec.rb')
        expect(File).to exist(spec_file)

        spec_content = File.read(spec_file)
        expect(spec_content).to include('account_id')
      end
    end
  end

  it 'spec files berada sejajar dengan code files' do
    Dir.mktmpdir do |dir|
      Dir.chdir(dir) do
        # Setup minimal
        FileUtils.mkdir_p(RiderKick.configuration.domains_path)
        FileUtils.mkdir_p('app/models/models')
        FileUtils.mkdir_p('db/structures')

        Object.send(:remove_const, :Models) if Object.const_defined?(:Models)
        Object.send(:remove_const, :Column) if Object.const_defined?(:Column)
        module Models; end

        Column = Struct.new(:name, :type, :sql_type, :null, :default, :precision, :scale, :limit)
        class Models::Item
          def self.columns
            [Column.new('id', :uuid), Column.new('name', :string)]
          end

          def self.columns_hash
            columns.to_h { |c| [c.name.to_s, Struct.new(:type).new(c.type)] }
          end

          def self.column_names
            columns.map { |c| c.name.to_s }
          end
        end

        File.write('app/models/models/item.rb', "class Models::Item < ApplicationRecord; end\n")
        File.write('db/structures/items_structure.yaml', <<~YAML)
          model: Models::Item
          resource_name: items
          actor: user
          resource_owner_id: account_id
          resource_owner: account
          uploaders: []
          search_able: []
          domains:
            action_list: { use_case: { contract: [] }, repository: { filters: [] } }
            action_fetch_by_id: { use_case: { contract: [] } }
            action_create: { use_case: { contract: [] } }
            action_update: { use_case: { contract: [] } }
            action_destroy: { use_case: { contract: [] } }
          entity: { db_attributes: [name] }
        YAML

        instance = klass.new(['items'])
        instance.generate_use_case

        # Verifikasi lokasi file spec sejajar dengan code files
        use_case_dir = File.join(RiderKick.configuration.domains_path + '/use_cases/items')
        expect(File).to exist(File.join(use_case_dir, 'user_create_item.rb'))
        expect(File).to exist(File.join(use_case_dir, 'user_create_item_spec.rb'))

        repository_dir = File.join(RiderKick.configuration.domains_path + '/repositories/items')
        expect(File).to exist(File.join(repository_dir, 'create_item.rb'))
        expect(File).to exist(File.join(repository_dir, 'create_item_spec.rb'))

        builders_dir = RiderKick.configuration.domains_path + '/builders'
        expect(File).to exist(File.join(builders_dir, 'item.rb'))
        expect(File).to exist(File.join(builders_dir, 'item_spec.rb'))

        # Entity spec is NOT generated - builder spec covers entity validation
        entities_dir = RiderKick.configuration.domains_path + '/entities'
        expect(File).to exist(File.join(entities_dir, 'item.rb'))
        expect(File).not_to exist(File.join(entities_dir, 'item_spec.rb'))
      end
    end
  end
end
