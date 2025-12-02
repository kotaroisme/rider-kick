# frozen_string_literal: true

require 'rails/generators'
require 'tmpdir'
require 'fileutils'
require 'yaml'
require 'debug'
require 'generators/rider_kick/structure_generator'

# Define Column struct at top level to avoid dynamic constant assignment warning
TestColumn = Struct.new(:name, :type, :sql_type, :null, :default, :precision, :scale, :limit) unless defined?(TestColumn)

RSpec.describe 'rider_kick:structure generator (comprehensive)' do
  let(:klass) { RiderKick::Structure }

  def create_test_model(module_name: 'Models', class_name: 'Article', columns: [])
    Object.send(:remove_const, :Models) if Object.const_defined?(:Models)

    unless Object.const_defined?(module_name.to_sym)
      Object.const_set(module_name.to_sym, Module.new)
    end

    model_class = Class.new do
      define_singleton_method(:columns) { columns }

      define_singleton_method(:columns_hash) do
        columns.to_h { |c| [c.name.to_s, Struct.new(:type).new(c.type)] }
      end

      define_singleton_method(:column_names) do
        columns.map { |c| c.name.to_s }
      end
    end

    module_obj = Object.const_get(module_name)
    module_obj.const_set(class_name.to_sym, model_class)

    "#{module_name}::#{class_name}".constantize
  end

  def create_test_columns
    [
      TestColumn.new('id', :uuid, 'uuid', false),
      TestColumn.new('account_id', :uuid, 'uuid', true),
      TestColumn.new('title', :string, 'character varying', true),
      TestColumn.new('body', :text, 'text', true),
      TestColumn.new('published_at', :datetime, 'timestamp without time zone', true),
      TestColumn.new('user_id', :uuid, 'uuid', true),
      TestColumn.new('images', :text, 'text', true),
      TestColumn.new('created_at', :datetime, 'timestamp without time zone', false),
      TestColumn.new('updated_at', :datetime, 'timestamp without time zone', false)
    ]
  end

  before do
    RiderKick.configuration.engine_name = nil
  end

  describe 'structure file generation' do
    it 'generates complete structure file with all sections' do
      Dir.mktmpdir do |dir|
        Dir.chdir(dir) do
          FileUtils.mkdir_p(RiderKick.configuration.domains_path + '/use_cases')
          FileUtils.mkdir_p('app/models/models')

          create_test_model(class_name: 'Article', columns: create_test_columns)

          instance = klass.new(['Models::Article', 'actor:owner', 'uploaders:images,assets', 'search_able:title,body', 'resource_owner_id:account_id', 'resource_owner:account'])
          allow(instance).to receive(:options).and_return({ engine: nil })
          instance.generate_use_case

          expect(File).to exist('db/structures/articles_structure.yaml')

          yaml_content = File.read('db/structures/articles_structure.yaml')
          parsed = YAML.load(yaml_content)

          # Verify basic structure
          expect(parsed['model']).to eq('Models::Article')
          expect(parsed['resource_name']).to eq('articles')
          expect(parsed['actor']).to eq('owner')
          expect(parsed['resource_owner_id']).to eq('account_id')
          expect(parsed['resource_owner']).to eq('account')
        end
      end
    end

    it 'generates correct fields section' do
      Dir.mktmpdir do |dir|
        Dir.chdir(dir) do
          FileUtils.mkdir_p(RiderKick.configuration.domains_path + '/use_cases')
          FileUtils.mkdir_p('app/models/models')

          create_test_model(class_name: 'Article', columns: create_test_columns)

          instance = klass.new(['Models::Article', 'actor:owner', 'uploaders:images', 'resource_owner:account', 'resource_owner_id:account_id'])
          allow(instance).to receive(:options).and_return({ engine: nil })
          instance.generate_use_case

          yaml_content = File.read('db/structures/articles_structure.yaml')

          # Check that fields include database columns and uploaders
          expect(yaml_content).to include('- account_id')
          expect(yaml_content).to include('- title')
          expect(yaml_content).to include('- body')
          expect(yaml_content).to include('- images')
        end
      end
    end

    it 'generates uploaders section with inline empty array format' do
      Dir.mktmpdir do |dir|
        Dir.chdir(dir) do
          FileUtils.mkdir_p(RiderKick.configuration.domains_path + '/use_cases')
          FileUtils.mkdir_p('app/models/models')

          create_test_model(class_name: 'Article', columns: create_test_columns)

          # Test with empty uploaders
          instance = klass.new(['Models::Article', 'actor:owner', 'resource_owner:account', 'resource_owner_id:account_id'])
          allow(instance).to receive(:options).and_return({ engine: nil })
          instance.generate_use_case

          yaml_content = File.read('db/structures/articles_structure.yaml')

          # Should be inline format: uploaders: []
          expect(yaml_content).to match(/^uploaders:\s*\[\]/m)
          # Should not be multi-line (key on one line, [] on next line)
          expect(yaml_content).not_to match(/^uploaders:\s*\n\s*\[\]/m)
        end
      end
    end

    it 'generates uploaders section with uploader definitions' do
      Dir.mktmpdir do |dir|
        Dir.chdir(dir) do
          FileUtils.mkdir_p(RiderKick.configuration.domains_path + '/use_cases')
          FileUtils.mkdir_p('app/models/models')

          create_test_model(class_name: 'Article', columns: create_test_columns)

          instance = klass.new(['Models::Article', 'actor:owner', 'uploaders:images,assets', 'resource_owner:account', 'resource_owner_id:account_id'])
          allow(instance).to receive(:options).and_return({ engine: nil })
          instance.generate_use_case

          yaml_content = File.read('db/structures/articles_structure.yaml')
          parsed = YAML.load(yaml_content)

          expect(parsed['uploaders']).to be_an(Array)
          expect(parsed['uploaders'].length).to eq(2)
          expect(parsed['uploaders']).to include({ 'name' => 'images', 'type' => 'multiple' })
          expect(parsed['uploaders']).to include({ 'name' => 'assets', 'type' => 'multiple' })
        end
      end
    end

    it 'generates search_able section with inline empty array format' do
      Dir.mktmpdir do |dir|
        Dir.chdir(dir) do
          FileUtils.mkdir_p(RiderKick.configuration.domains_path + '/use_cases')
          FileUtils.mkdir_p('app/models/models')

          create_test_model(class_name: 'Article', columns: create_test_columns)

          # Test with empty search_able
          instance = klass.new(['Models::Article', 'actor:owner', 'resource_owner:account', 'resource_owner_id:account_id'])
          allow(instance).to receive(:options).and_return({ engine: nil })
          instance.generate_use_case

          yaml_content = File.read('db/structures/articles_structure.yaml')

          # Should be inline format: search_able: []
          expect(yaml_content).to match(/^search_able:\s*\[\]/m)
        end
      end
    end

    it 'generates search_able section with searchable fields' do
      Dir.mktmpdir do |dir|
        Dir.chdir(dir) do
          FileUtils.mkdir_p(RiderKick.configuration.domains_path + '/use_cases')
          FileUtils.mkdir_p('app/models/models')

          create_test_model(class_name: 'Article', columns: create_test_columns)

          instance = klass.new(['Models::Article', 'actor:owner', 'search_able:title,body', 'resource_owner:account', 'resource_owner_id:account_id'])
          allow(instance).to receive(:options).and_return({ engine: nil })
          instance.generate_use_case

          yaml_content = File.read('db/structures/articles_structure.yaml')
          parsed = YAML.load(yaml_content)

          expect(parsed['search_able']).to be_an(Array)
          expect(parsed['search_able']).to include('title')
          expect(parsed['search_able']).to include('body')
        end
      end
    end

    it 'generates schema section with all column metadata' do
      Dir.mktmpdir do |dir|
        Dir.chdir(dir) do
          FileUtils.mkdir_p(RiderKick.configuration.domains_path + '/use_cases')
          FileUtils.mkdir_p('app/models/models')

          create_test_model(class_name: 'Article', columns: create_test_columns)

          instance = klass.new(['Models::Article', 'actor:owner', 'resource_owner:account', 'resource_owner_id:account_id'])
          allow(instance).to receive(:options).and_return({ engine: nil })
          instance.generate_use_case

          yaml_content = File.read('db/structures/articles_structure.yaml')
          parsed = YAML.load(yaml_content)

          expect(parsed['schema']).to be_a(Hash)
          expect(parsed['schema']['columns']).to be_an(Array)
          expect(parsed['schema']['columns'].length).to eq(9) # All columns including id, timestamps

          # Check column metadata
          id_column = parsed['schema']['columns'].find { |c| c['name'] == 'id' }
          expect(id_column['type']).to eq('uuid')
          # null can be nil, false, or 'null' string depending on column definition
          expect([false, nil, 'null']).to include(id_column['null'])
        end
      end
    end

    it 'generates schema foreign_keys with inline empty array format' do
      Dir.mktmpdir do |dir|
        Dir.chdir(dir) do
          FileUtils.mkdir_p(RiderKick.configuration.domains_path + '/use_cases')
          FileUtils.mkdir_p('app/models/models')

          create_test_model(class_name: 'Article', columns: create_test_columns)

          instance = klass.new(['Models::Article', 'actor:owner', 'resource_owner:account', 'resource_owner_id:account_id'])
          allow(instance).to receive(:options).and_return({ engine: nil })
          instance.generate_use_case

          yaml_content = File.read('db/structures/articles_structure.yaml')

          # Should be inline format: foreign_keys: []
          expect(yaml_content).to match(/^\s+foreign_keys:\s*\[\]/m)
        end
      end
    end

    it 'generates schema indexes with inline empty array format' do
      Dir.mktmpdir do |dir|
        Dir.chdir(dir) do
          FileUtils.mkdir_p(RiderKick.configuration.domains_path + '/use_cases')
          FileUtils.mkdir_p('app/models/models')

          create_test_model(class_name: 'Article', columns: create_test_columns)

          instance = klass.new(['Models::Article', 'actor:owner', 'resource_owner:account', 'resource_owner_id:account_id'])
          allow(instance).to receive(:options).and_return({ engine: nil })
          instance.generate_use_case

          yaml_content = File.read('db/structures/articles_structure.yaml')

          # Should be inline format: indexes: []
          expect(yaml_content).to match(/^\s+indexes:\s*\[\]/m)
        end
      end
    end

    it 'generates schema enums with empty object format' do
      Dir.mktmpdir do |dir|
        Dir.chdir(dir) do
          FileUtils.mkdir_p(RiderKick.configuration.domains_path + '/use_cases')
          FileUtils.mkdir_p('app/models/models')

          create_test_model(class_name: 'Article', columns: create_test_columns)

          instance = klass.new(['Models::Article', 'actor:owner', 'resource_owner:account', 'resource_owner_id:account_id'])
          allow(instance).to receive(:options).and_return({ engine: nil })
          instance.generate_use_case

          yaml_content = File.read('db/structures/articles_structure.yaml')
          parsed = YAML.load(yaml_content)

          expect(parsed['schema']['enums']).to eq({})
        end
      end
    end

    it 'generates controllers section with list_fields, show_fields, and form_fields' do
      Dir.mktmpdir do |dir|
        Dir.chdir(dir) do
          FileUtils.mkdir_p(RiderKick.configuration.domains_path + '/use_cases')
          FileUtils.mkdir_p('app/models/models')

          create_test_model(class_name: 'Article', columns: create_test_columns)

          instance = klass.new(['Models::Article', 'actor:owner', 'uploaders:images', 'resource_owner:account', 'resource_owner_id:account_id'])
          allow(instance).to receive(:options).and_return({ engine: nil })
          instance.generate_use_case

          yaml_content = File.read('db/structures/articles_structure.yaml')
          parsed = YAML.load(yaml_content)

          expect(parsed['controllers']).to be_a(Hash)
          expect(parsed['controllers']['list_fields']).to be_an(Array)
          expect(parsed['controllers']['show_fields']).to be_an(Array)
          expect(parsed['controllers']['form_fields']).to be_an(Array)

          # Check form_fields structure
          form_field = parsed['controllers']['form_fields'].find { |f| f['name'] == 'title' }
          expect(form_field['type']).to eq('string')

          uploader_field = parsed['controllers']['form_fields'].find { |f| f['name'] == 'images' }
          expect(uploader_field['type']).to eq('files')
        end
      end
    end

    it 'generates controllers section with inline empty arrays when empty' do
      Dir.mktmpdir do |dir|
        Dir.chdir(dir) do
          FileUtils.mkdir_p(RiderKick.configuration.domains_path + '/use_cases')
          FileUtils.mkdir_p('app/models/models')

          columns = [
            TestColumn.new('id', :uuid),
            TestColumn.new('created_at', :datetime),
            TestColumn.new('updated_at', :datetime)
          ]
          create_test_model(class_name: 'Article', columns: columns)

          instance = klass.new(['Models::Article', 'actor:owner', 'resource_owner:account', 'resource_owner_id:account_id'])
          allow(instance).to receive(:options).and_return({ engine: nil })
          instance.generate_use_case

          yaml_content = File.read('db/structures/articles_structure.yaml')
          parsed = YAML.load(yaml_content)
          # Should be inline format for empty arrays
          expect(yaml_content).to match(/^\s+list_fields:\s*\[\]/m)
          # show_fields will always have at least id, created_at, updated_at
          expect(parsed['controllers']['show_fields']).to be_an(Array)
          expect(parsed['controllers']['show_fields']).to include('id', 'created_at', 'updated_at')
          expect(yaml_content).to match(/^\s+form_fields:\s*\[\]/m)
        end
      end
    end

    it 'generates domains section with all action contracts' do
      Dir.mktmpdir do |dir|
        Dir.chdir(dir) do
          FileUtils.mkdir_p(RiderKick.configuration.domains_path + '/use_cases')
          FileUtils.mkdir_p('app/models/models')

          create_test_model(class_name: 'Article', columns: create_test_columns)

          instance = klass.new(['Models::Article', 'actor:owner', 'search_able:title', 'resource_owner:account', 'resource_owner_id:account_id'])
          allow(instance).to receive(:options).and_return({ engine: nil })
          instance.generate_use_case

          yaml_content = File.read('db/structures/articles_structure.yaml')
          parsed = YAML.load(yaml_content)

          expect(parsed['domains']).to be_a(Hash)

          # Check action_list
          expect(parsed['domains']['action_list']['use_case']['contract']).to be_an(Array)
          expect(parsed['domains']['action_list']['repository']['filters']).to be_an(Array)

          # Check action_fetch_by_id
          expect(parsed['domains']['action_fetch_by_id']['use_case']['contract']).to be_an(Array)
          expect(parsed['domains']['action_fetch_by_id']['use_case']['contract'].first).to include('required(:id).filled(:string)')

          # Check action_create
          expect(parsed['domains']['action_create']['use_case']['contract']).to be_an(Array)

          # Check action_update
          expect(parsed['domains']['action_update']['use_case']['contract']).to be_an(Array)
          expect(parsed['domains']['action_update']['use_case']['contract'].first).to include('required(:id).filled(:string)')

          # Check action_destroy
          expect(parsed['domains']['action_destroy']['use_case']['contract']).to be_an(Array)
          expect(parsed['domains']['action_destroy']['use_case']['contract'].first).to include('required(:id).filled(:string)')
        end
      end
    end

    it 'generates action_fetch_by_id contract with required id and resource_owner_id' do
      Dir.mktmpdir do |dir|
        Dir.chdir(dir) do
          FileUtils.mkdir_p(RiderKick.configuration.domains_path + '/use_cases')
          FileUtils.mkdir_p('app/models/models')

          create_test_model(class_name: 'Article', columns: create_test_columns)

          instance = klass.new(['Models::Article', 'actor:owner', 'resource_owner_id:account_id', 'resource_owner:account'])
          allow(instance).to receive(:options).and_return({ engine: nil })
          instance.generate_use_case

          yaml_content = File.read('db/structures/articles_structure.yaml')
          parsed = YAML.load(yaml_content)

          contract = parsed['domains']['action_fetch_by_id']['use_case']['contract']
          expect(contract).to include(match(/required\(:id\)\.filled\(:string\)/))
          expect(contract).to include(match(/required\(:account_id\)\.filled\(:string\)/))
        end
      end
    end

    it 'generates action_create contract with all fields and resource_owner_id' do
      Dir.mktmpdir do |dir|
        Dir.chdir(dir) do
          FileUtils.mkdir_p(RiderKick.configuration.domains_path + '/use_cases')
          FileUtils.mkdir_p('app/models/models')

          create_test_model(class_name: 'Article', columns: create_test_columns)

          instance = klass.new(['Models::Article', 'actor:owner', 'resource_owner_id:account_id', 'uploaders:images', 'resource_owner:account'])
          allow(instance).to receive(:options).and_return({ engine: nil })
          instance.generate_use_case

          yaml_content = File.read('db/structures/articles_structure.yaml')
          parsed = YAML.load(yaml_content)

          contract = parsed['domains']['action_create']['use_case']['contract']
          expect(contract).to include(match(/required\(:account_id\)\.filled\(:string\)/))
          expect(contract.any? { |c| c.include?('title') }).to be true
          expect(contract.any? { |c| c.include?('body') }).to be true
        end
      end
    end

    it 'generates action_update contract with required id' do
      Dir.mktmpdir do |dir|
        Dir.chdir(dir) do
          FileUtils.mkdir_p(RiderKick.configuration.domains_path + '/use_cases')
          FileUtils.mkdir_p('app/models/models')

          create_test_model(class_name: 'Article', columns: create_test_columns)

          instance = klass.new(['Models::Article', 'actor:owner', 'uploaders:images', 'resource_owner:account', 'resource_owner_id:account_id'])
          allow(instance).to receive(:options).and_return({ engine: nil })
          instance.generate_use_case

          yaml_content = File.read('db/structures/articles_structure.yaml')
          parsed = YAML.load(yaml_content)

          contract = parsed['domains']['action_update']['use_case']['contract']
          expect(contract.first).to include('required(:id).filled(:string)')
          expect(contract.any? { |c| c.include?('title') }).to be true
        end
      end
    end

    it 'generates action_destroy contract with required id and resource_owner_id' do
      Dir.mktmpdir do |dir|
        Dir.chdir(dir) do
          FileUtils.mkdir_p(RiderKick.configuration.domains_path + '/use_cases')
          FileUtils.mkdir_p('app/models/models')

          create_test_model(class_name: 'Article', columns: create_test_columns)

          instance = klass.new(['Models::Article', 'actor:owner', 'resource_owner_id:account_id', 'resource_owner:account'])
          allow(instance).to receive(:options).and_return({ engine: nil })
          instance.generate_use_case

          yaml_content = File.read('db/structures/articles_structure.yaml')
          parsed = YAML.load(yaml_content)

          contract = parsed['domains']['action_destroy']['use_case']['contract']
          expect(contract).to include(match(/required\(:id\)\.filled\(:string\)/))
          expect(contract).to include(match(/required\(:account_id\)\.filled\(:string\)/))
        end
      end
    end

    it 'generates domains contracts with inline empty arrays when empty' do
      Dir.mktmpdir do |dir|
        Dir.chdir(dir) do
          FileUtils.mkdir_p(RiderKick.configuration.domains_path + '/use_cases')
          FileUtils.mkdir_p('app/models/models')

          columns = [
            TestColumn.new('id', :uuid),
            TestColumn.new('created_at', :datetime),
            TestColumn.new('updated_at', :datetime)
          ]
          create_test_model(class_name: 'Article', columns: columns)

          instance = klass.new(['Models::Article', 'actor:owner', 'resource_owner:account', 'resource_owner_id:account_id'])
          allow(instance).to receive(:options).and_return({ engine: nil })
          instance.generate_use_case

          yaml_content = File.read('db/structures/articles_structure.yaml')

          # Should be inline format for empty contract arrays
          expect(yaml_content).to match(/^\s+contract:\s*\[\]/m)
          expect(yaml_content).to match(/^\s+filters:\s*\[\]/m)
        end
      end
    end

    it 'generates entity section with skipped_fields and db_attributes' do
      Dir.mktmpdir do |dir|
        Dir.chdir(dir) do
          FileUtils.mkdir_p(RiderKick.configuration.domains_path + '/use_cases')
          FileUtils.mkdir_p('app/models/models')

          create_test_model(class_name: 'Article', columns: create_test_columns)

          instance = klass.new(['Models::Article', 'actor:owner', 'resource_owner:account', 'resource_owner_id:account_id'])
          allow(instance).to receive(:options).and_return({ engine: nil })
          instance.generate_use_case

          yaml_content = File.read('db/structures/articles_structure.yaml')
          parsed = YAML.load(yaml_content)

          expect(parsed['entity']).to be_a(Hash)
          expect(parsed['entity']['skipped_fields']).to include('id', 'created_at', 'updated_at')
          expect(parsed['entity']['db_attributes']).to be_an(Array)
          expect(parsed['entity']['db_attributes']).to include('account_id', 'title', 'body')
        end
      end
    end

    it 'generates entity db_attributes with inline empty array when empty' do
      Dir.mktmpdir do |dir|
        Dir.chdir(dir) do
          FileUtils.mkdir_p(RiderKick.configuration.domains_path + '/use_cases')
          FileUtils.mkdir_p('app/models/models')

          columns = [
            TestColumn.new('id', :uuid),
            TestColumn.new('created_at', :datetime),
            TestColumn.new('updated_at', :datetime)
          ]
          create_test_model(class_name: 'Article', columns: columns)

          instance = klass.new(['Models::Article', 'actor:owner', 'resource_owner:account', 'resource_owner_id:account_id'])
          allow(instance).to receive(:options).and_return({ engine: nil })
          instance.generate_use_case

          yaml_content = File.read('db/structures/articles_structure.yaml')

          # Should be inline format: db_attributes: []
          expect(yaml_content).to match(/^\s+db_attributes:\s*\[\]/m)
        end
      end
    end

    it 'generates valid YAML that can be parsed without errors' do
      Dir.mktmpdir do |dir|
        Dir.chdir(dir) do
          FileUtils.mkdir_p(RiderKick.configuration.domains_path + '/use_cases')
          FileUtils.mkdir_p('app/models/models')

          create_test_model(class_name: 'Article', columns: create_test_columns)

          instance = klass.new(['Models::Article', 'actor:owner', 'uploaders:images,assets', 'search_able:title,body', 'resource_owner_id:account_id', 'resource_owner:account'])
          allow(instance).to receive(:options).and_return({ engine: nil })
          instance.generate_use_case

          yaml_content = File.read('db/structures/articles_structure.yaml')

          # Should parse without errors
          expect { YAML.load(yaml_content) }.not_to raise_error

          parsed = YAML.load(yaml_content)
          expect(parsed).to be_a(Hash)
        end
      end
    end

    it 'generates correct YAML indentation (2 spaces per level)' do
      Dir.mktmpdir do |dir|
        Dir.chdir(dir) do
          FileUtils.mkdir_p(RiderKick.configuration.domains_path + '/use_cases')
          FileUtils.mkdir_p('app/models/models')

          create_test_model(class_name: 'Article', columns: create_test_columns)

          instance = klass.new(['Models::Article', 'actor:owner', 'uploaders:images', 'resource_owner:account', 'resource_owner_id:account_id'])
          allow(instance).to receive(:options).and_return({ engine: nil })
          instance.generate_use_case

          yaml_content = File.read('db/structures/articles_structure.yaml')

          # Check indentation for nested sections
          lines = yaml_content.split("\n")
          schema_line = lines.find { |l| l.include?('schema:') }
          lines.index(schema_line)
          columns_line = lines.find { |l| l.include?('columns:') }
          columns_index = lines.index(columns_line)

          # columns should be indented 2 spaces from schema
          expect(lines[columns_index]).to start_with('  columns:')
        end
      end
    end
  end
end
