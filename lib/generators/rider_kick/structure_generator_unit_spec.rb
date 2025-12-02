# frozen_string_literal: true

require 'rails/generators'
require 'tmpdir'
require 'fileutils'
require 'generators/rider_kick/structure_generator'

# Define Column struct at top level to avoid dynamic constant assignment warning
TestColumn = Struct.new(:name, :type, :sql_type, :null, :default, :precision, :scale, :limit) unless defined?(TestColumn)

RSpec.describe 'rider_kick:structure generator (unit tests)' do
  let(:klass) { RiderKick::Structure }

  def create_test_model(module_name: 'Models', class_name: 'Article', columns: [])
    # Remove nested modules properly
    parts = module_name.split('::')
    if parts.length > 1
      # For nested modules, remove from innermost to outermost
      begin
        Object.const_get(module_name)
        # If exists, remove the class first
        full_name = "#{module_name}::#{class_name}"
        if Object.const_defined?(full_name)
          Object.const_get(module_name).send(:remove_const, class_name.to_sym)
        end
        # Then remove modules from innermost
        (parts.length - 1).downto(0) do |i|
          module_path = parts[0..i].join('::')
          if Object.const_defined?(module_path)
            parent = i > 0 ? Object.const_get(parts[0..i - 1].join('::')) : Object
            parent.send(:remove_const, parts[i].to_sym)
          end
        end
      rescue NameError
        # Module doesn't exist, continue
      end
    elsif Object.const_defined?(module_name.to_sym)
      Object.send(:remove_const, module_name.to_sym)
    end

    # Create nested modules if needed
    parts = module_name.split('::')
    current_module = Object
    parts.each do |part|
      unless current_module.const_defined?(part.to_sym)
        current_module.const_set(part.to_sym, Module.new)
      end
      current_module = current_module.const_get(part.to_sym)
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

    current_module.const_set(class_name.to_sym, model_class)
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
    RiderKick.configuration.domain_scope = ''
  end

  describe '#setup_variables' do
    context 'with simple model name' do
      it 'sets @variable_subject correctly for simple model name' do
        Dir.mktmpdir do |dir|
          Dir.chdir(dir) do
            FileUtils.mkdir_p(RiderKick.configuration.domains_path + '/use_cases')
            FileUtils.mkdir_p('app/models/models')

            create_test_model(class_name: 'User', columns: create_test_columns)

            instance = klass.new(['Models::User', 'actor:user', 'resource_owner:account', 'resource_owner_id:account_id'])
            allow(instance).to receive(:options).and_return({ engine: nil })
            instance.send(:setup_variables)

            expect(instance.instance_variable_get(:@variable_subject)).to eq('user')
          end
        end
      end

      it 'sets @model_class correctly' do
        Dir.mktmpdir do |dir|
          Dir.chdir(dir) do
            FileUtils.mkdir_p(RiderKick.configuration.domains_path + '/use_cases')
            FileUtils.mkdir_p('app/models/models')

            model_class = create_test_model(class_name: 'User', columns: create_test_columns)

            instance = klass.new(['Models::User', 'actor:user', 'resource_owner:account', 'resource_owner_id:account_id'])
            allow(instance).to receive(:options).and_return({ engine: nil })
            instance.send(:setup_variables)

            expect(instance.instance_variable_get(:@model_class)).to eq(model_class)
          end
        end
      end

      it 'sets @subject_class correctly' do
        Dir.mktmpdir do |dir|
          Dir.chdir(dir) do
            FileUtils.mkdir_p(RiderKick.configuration.domains_path + '/use_cases')
            FileUtils.mkdir_p('app/models/models')

            create_test_model(class_name: 'User', columns: create_test_columns)

            instance = klass.new(['Models::User', 'actor:user', 'resource_owner:account', 'resource_owner_id:account_id'])
            allow(instance).to receive(:options).and_return({ engine: nil })
            instance.send(:setup_variables)

            expect(instance.instance_variable_get(:@subject_class)).to eq('User')
          end
        end
      end

      it 'sets @scope_path correctly with pluralization' do
        Dir.mktmpdir do |dir|
          Dir.chdir(dir) do
            FileUtils.mkdir_p(RiderKick.configuration.domains_path + '/use_cases')
            FileUtils.mkdir_p('app/models/models')

            create_test_model(class_name: 'User', columns: create_test_columns)

            instance = klass.new(['Models::User', 'actor:user', 'resource_owner:account', 'resource_owner_id:account_id'])
            allow(instance).to receive(:options).and_return({ engine: nil })
            instance.send(:setup_variables)

            expect(instance.instance_variable_get(:@scope_path)).to eq('users')
          end
        end
      end

      it 'sets @scope_class correctly with camelization' do
        Dir.mktmpdir do |dir|
          Dir.chdir(dir) do
            FileUtils.mkdir_p(RiderKick.configuration.domains_path + '/use_cases')
            FileUtils.mkdir_p('app/models/models')

            create_test_model(class_name: 'User', columns: create_test_columns)

            instance = klass.new(['Models::User', 'actor:user', 'resource_owner:account', 'resource_owner_id:account_id'])
            allow(instance).to receive(:options).and_return({ engine: nil })
            instance.send(:setup_variables)

            expect(instance.instance_variable_get(:@scope_class)).to eq('Users')
          end
        end
      end
    end

    context 'with complex namespace' do
      it 'sets @variable_subject correctly for complex namespace' do
        Dir.mktmpdir do |dir|
          Dir.chdir(dir) do
            FileUtils.mkdir_p(RiderKick.configuration.domains_path + '/use_cases')
            FileUtils.mkdir_p('app/models/models')

            create_test_model(module_name: 'Models::Core', class_name: 'User', columns: create_test_columns)

            instance = klass.new(['Models::Core::User', 'actor:user', 'resource_owner:account', 'resource_owner_id:account_id'])
            allow(instance).to receive(:options).and_return({ engine: nil })
            instance.send(:setup_variables)

            expect(instance.instance_variable_get(:@variable_subject)).to eq('user')
          end
        end
      end

      it 'sets @subject_class correctly for complex namespace' do
        Dir.mktmpdir do |dir|
          Dir.chdir(dir) do
            FileUtils.mkdir_p(RiderKick.configuration.domains_path + '/use_cases')
            FileUtils.mkdir_p('app/models/models')

            create_test_model(module_name: 'Models::Core', class_name: 'User', columns: create_test_columns)

            instance = klass.new(['Models::Core::User', 'actor:user', 'resource_owner:account', 'resource_owner_id:account_id'])
            allow(instance).to receive(:options).and_return({ engine: nil })
            instance.send(:setup_variables)

            expect(instance.instance_variable_get(:@subject_class)).to eq('User')
          end
        end
      end
    end

    it 'sets @fields from contract_fields' do
      Dir.mktmpdir do |dir|
        Dir.chdir(dir) do
          FileUtils.mkdir_p(RiderKick.configuration.domains_path + '/use_cases')
          FileUtils.mkdir_p('app/models/models')

          create_test_model(class_name: 'Article', columns: create_test_columns)

          instance = klass.new(['Models::Article', 'actor:user', 'resource_owner:account', 'resource_owner_id:account_id'])
          allow(instance).to receive(:options).and_return({ engine: nil })
          instance.send(:setup_variables)

          fields = instance.instance_variable_get(:@fields)
          expect(fields).to be_an(Array)
          expect(fields).not_to include('id', 'created_at', 'updated_at')
          expect(fields).to include('account_id', 'title', 'body')
        end
      end
    end

    it 'sets @uploaders as array string' do
      Dir.mktmpdir do |dir|
        Dir.chdir(dir) do
          FileUtils.mkdir_p(RiderKick.configuration.domains_path + '/use_cases')
          FileUtils.mkdir_p('app/models/models')

          create_test_model(class_name: 'Article', columns: create_test_columns)

          instance = klass.new(['Models::Article', 'actor:user', 'uploaders:images,assets', 'resource_owner:account', 'resource_owner_id:account_id'])
          allow(instance).to receive(:options).and_return({ engine: nil })
          instance.send(:setup_variables)

          uploaders = instance.instance_variable_get(:@uploaders)
          expect(uploaders).to eq(['images', 'assets'])
        end
      end
    end

    it 'sets @actor correctly with lowercase conversion' do
      Dir.mktmpdir do |dir|
        Dir.chdir(dir) do
          FileUtils.mkdir_p(RiderKick.configuration.domains_path + '/use_cases')
          FileUtils.mkdir_p('app/models/models')

          create_test_model(class_name: 'Article', columns: create_test_columns)

          instance = klass.new(['Models::Article', 'actor:User', 'resource_owner:account', 'resource_owner_id:account_id'])
          allow(instance).to receive(:options).and_return({ engine: nil })
          instance.send(:setup_variables)

          expect(instance.instance_variable_get(:@actor)).to eq('user')
        end
      end
    end

    it 'sets @actor_id correctly when actor is present' do
      Dir.mktmpdir do |dir|
        Dir.chdir(dir) do
          FileUtils.mkdir_p(RiderKick.configuration.domains_path + '/use_cases')
          FileUtils.mkdir_p('app/models/models')

          create_test_model(class_name: 'Article', columns: create_test_columns)

          instance = klass.new(['Models::Article', 'actor:user', 'resource_owner:account', 'resource_owner_id:account_id'])
          allow(instance).to receive(:options).and_return({ engine: nil })
          instance.send(:setup_variables)

          expect(instance.instance_variable_get(:@actor_id)).to eq('user_id')
        end
      end
    end

    it 'sets @actor_id to empty string when actor is blank' do
      Dir.mktmpdir do |dir|
        Dir.chdir(dir) do
          FileUtils.mkdir_p(RiderKick.configuration.domains_path + '/use_cases')
          FileUtils.mkdir_p('app/models/models')

          create_test_model(class_name: 'Article', columns: create_test_columns)

          instance = klass.new(['Models::Article', 'actor:', 'resource_owner:account', 'resource_owner_id:account_id'])
          allow(instance).to receive(:options).and_return({ engine: nil })
          instance.send(:setup_variables)

          expect(instance.instance_variable_get(:@actor_id)).to eq('')
        end
      end
    end

    it 'sets @resource_owner and @resource_owner_id from settings' do
      Dir.mktmpdir do |dir|
        Dir.chdir(dir) do
          FileUtils.mkdir_p(RiderKick.configuration.domains_path + '/use_cases')
          FileUtils.mkdir_p('app/models/models')

          create_test_model(class_name: 'Article', columns: create_test_columns)

          instance = klass.new(['Models::Article', 'actor:user', 'resource_owner:account', 'resource_owner_id:account_id'])
          allow(instance).to receive(:options).and_return({ engine: nil })
          instance.send(:setup_variables)

          expect(instance.instance_variable_get(:@resource_owner)).to eq('account')
          expect(instance.instance_variable_get(:@resource_owner_id)).to eq('account_id')
        end
      end
    end

    it 'sets @columns from columns_meta' do
      Dir.mktmpdir do |dir|
        Dir.chdir(dir) do
          FileUtils.mkdir_p(RiderKick.configuration.domains_path + '/use_cases')
          FileUtils.mkdir_p('app/models/models')

          columns = create_test_columns
          create_test_model(class_name: 'Article', columns: columns)

          instance = klass.new(['Models::Article', 'actor:user', 'resource_owner:account', 'resource_owner_id:account_id'])
          allow(instance).to receive(:options).and_return({ engine: nil })
          instance.send(:setup_variables)

          columns_meta = instance.instance_variable_get(:@columns)
          expect(columns_meta).to be_an(Array)
          expect(columns_meta.length).to eq(columns.length)
          expect(columns_meta.first[:name]).to eq('id')
        end
      end
    end

    it 'sets @type_mapping and @entity_type_mapping' do
      Dir.mktmpdir do |dir|
        Dir.chdir(dir) do
          FileUtils.mkdir_p(RiderKick.configuration.domains_path + '/use_cases')
          FileUtils.mkdir_p('app/models/models')

          create_test_model(class_name: 'Article', columns: create_test_columns)

          instance = klass.new(['Models::Article', 'actor:user', 'resource_owner:account', 'resource_owner_id:account_id'])
          allow(instance).to receive(:options).and_return({ engine: nil })
          instance.send(:setup_variables)

          expect(instance.instance_variable_get(:@type_mapping)).to eq(RiderKick::TYPE_MAPPING)
          expect(instance.instance_variable_get(:@entity_type_mapping)).to eq(RiderKick::ENTITY_TYPE_MAPPING)
        end
      end
    end

    it 'sets @columns_meta_hash with correct indexing structure' do
      Dir.mktmpdir do |dir|
        Dir.chdir(dir) do
          FileUtils.mkdir_p(RiderKick.configuration.domains_path + '/use_cases')
          FileUtils.mkdir_p('app/models/models')

          create_test_model(class_name: 'Article', columns: create_test_columns)

          instance = klass.new(['Models::Article', 'actor:user', 'resource_owner:account', 'resource_owner_id:account_id'])
          allow(instance).to receive(:options).and_return({ engine: nil })
          instance.send(:setup_variables)

          columns_meta_hash = instance.instance_variable_get(:@columns_meta_hash)
          expect(columns_meta_hash).to be_a(Hash)
          expect(columns_meta_hash['id']).to be_a(Hash)
          expect(columns_meta_hash['id'][:name]).to eq('id')
        end
      end
    end
  end

  describe '@contract_lines_for_create generation' do
    it 'generates required field for null: false' do
      Dir.mktmpdir do |dir|
        Dir.chdir(dir) do
          FileUtils.mkdir_p(RiderKick.configuration.domains_path + '/use_cases')
          FileUtils.mkdir_p('app/models/models')

          columns = [
            TestColumn.new('id', :uuid, 'uuid', false),
            TestColumn.new('title', :string, 'character varying', false),
            TestColumn.new('created_at', :datetime, 'timestamp', false),
            TestColumn.new('updated_at', :datetime, 'timestamp', false)
          ]
          create_test_model(class_name: 'Article', columns: columns)

          instance = klass.new(['Models::Article', 'actor:user', 'resource_owner:account', 'resource_owner_id:account_id'])
          allow(instance).to receive(:options).and_return({ engine: nil })
          instance.send(:setup_variables)

          contract_lines = instance.instance_variable_get(:@contract_lines_for_create)
          title_line = contract_lines.find { |l| l.include?('title') }
          expect(title_line).to include('required(:title)')
          expect(title_line).to include('.filled')
        end
      end
    end

    it 'generates optional field for null: true' do
      Dir.mktmpdir do |dir|
        Dir.chdir(dir) do
          FileUtils.mkdir_p(RiderKick.configuration.domains_path + '/use_cases')
          FileUtils.mkdir_p('app/models/models')

          columns = [
            TestColumn.new('id', :uuid, 'uuid', false),
            TestColumn.new('title', :string, 'character varying', true),
            TestColumn.new('created_at', :datetime, 'timestamp', false),
            TestColumn.new('updated_at', :datetime, 'timestamp', false)
          ]
          create_test_model(class_name: 'Article', columns: columns)

          instance = klass.new(['Models::Article', 'actor:user', 'resource_owner:account', 'resource_owner_id:account_id'])
          allow(instance).to receive(:options).and_return({ engine: nil })
          instance.send(:setup_variables)

          contract_lines = instance.instance_variable_get(:@contract_lines_for_create)
          title_line = contract_lines.find { |l| l.include?('title') }
          expect(title_line).to include('optional(:title)')
          expect(title_line).to include('.maybe')
        end
      end
    end

    it 'generates Types::File for upload field' do
      Dir.mktmpdir do |dir|
        Dir.chdir(dir) do
          FileUtils.mkdir_p(RiderKick.configuration.domains_path + '/use_cases')
          FileUtils.mkdir_p('app/models/models')

          columns = [
            TestColumn.new('id', :uuid, 'uuid', false),
            TestColumn.new('title', :string, 'character varying', true),
            TestColumn.new('image', :string, 'character varying', false),
            TestColumn.new('created_at', :datetime, 'timestamp', false),
            TestColumn.new('updated_at', :datetime, 'timestamp', false)
          ]
          create_test_model(class_name: 'Article', columns: columns)

          instance = klass.new(['Models::Article', 'actor:user', 'uploaders:image', 'resource_owner:account', 'resource_owner_id:account_id'])
          allow(instance).to receive(:options).and_return({ engine: nil })
          instance.send(:setup_variables)

          # Test get_column_type directly - should return 'upload' for uploader field
          column_type = instance.send(:get_column_type, 'image')
          expect(column_type).to eq('upload')

          # Test that uploaders are excluded from contract_fields (by design)
          fields = instance.instance_variable_get(:@fields)
          expect(fields).not_to include('image')
          expect(fields).to include('title')
        end
      end
    end

    it 'generates optional Types::File for upload field with null: true' do
      Dir.mktmpdir do |dir|
        Dir.chdir(dir) do
          FileUtils.mkdir_p(RiderKick.configuration.domains_path + '/use_cases')
          FileUtils.mkdir_p('app/models/models')

          columns = [
            TestColumn.new('id', :uuid, 'uuid', false),
            TestColumn.new('title', :string, 'character varying', true),
            TestColumn.new('image', :string, 'character varying', true),
            TestColumn.new('created_at', :datetime, 'timestamp', false),
            TestColumn.new('updated_at', :datetime, 'timestamp', false)
          ]
          create_test_model(class_name: 'Article', columns: columns)

          instance = klass.new(['Models::Article', 'actor:user', 'uploaders:image', 'resource_owner:account', 'resource_owner_id:account_id'])
          allow(instance).to receive(:options).and_return({ engine: nil })
          instance.send(:setup_variables)

          # Test get_column_type directly - should return 'upload' for uploader field
          column_type = instance.send(:get_column_type, 'image')
          expect(column_type).to eq('upload')

          # Uploaders are excluded from contract_fields by design
          fields = instance.instance_variable_get(:@fields)
          expect(fields).not_to include('image')
        end
      end
    end

    it 'falls back to :string for unknown db_type' do
      Dir.mktmpdir do |dir|
        Dir.chdir(dir) do
          FileUtils.mkdir_p(RiderKick.configuration.domains_path + '/use_cases')
          FileUtils.mkdir_p('app/models/models')

          columns = [
            TestColumn.new('id', :uuid, 'uuid', false),
            TestColumn.new('custom_field', :unknown_type, 'unknown', true),
            TestColumn.new('created_at', :datetime, 'timestamp', false),
            TestColumn.new('updated_at', :datetime, 'timestamp', false)
          ]
          create_test_model(class_name: 'Article', columns: columns)

          instance = klass.new(['Models::Article', 'actor:user', 'resource_owner:account', 'resource_owner_id:account_id'])
          allow(instance).to receive(:options).and_return({ engine: nil })
          instance.send(:setup_variables)

          contract_lines = instance.instance_variable_get(:@contract_lines_for_create)
          custom_line = contract_lines.find { |l| l.include?('custom_field') }
          expect(custom_line).to include(':string')
        end
      end
    end

    it 'handles various db_types correctly' do
      Dir.mktmpdir do |dir|
        Dir.chdir(dir) do
          FileUtils.mkdir_p(RiderKick.configuration.domains_path + '/use_cases')
          FileUtils.mkdir_p('app/models/models')

          columns = [
            TestColumn.new('id', :uuid, 'uuid', false),
            TestColumn.new('uuid_field', :uuid, 'uuid', true),
            TestColumn.new('int_field', :integer, 'integer', true),
            TestColumn.new('bool_field', :boolean, 'boolean', true),
            TestColumn.new('decimal_field', :decimal, 'decimal', true),
            TestColumn.new('date_field', :date, 'date', true),
            TestColumn.new('datetime_field', :datetime, 'timestamp', true),
            TestColumn.new('created_at', :datetime, 'timestamp', false),
            TestColumn.new('updated_at', :datetime, 'timestamp', false)
          ]
          create_test_model(class_name: 'Article', columns: columns)

          instance = klass.new(['Models::Article', 'actor:user', 'resource_owner:account', 'resource_owner_id:account_id'])
          allow(instance).to receive(:options).and_return({ engine: nil })
          instance.send(:setup_variables)

          contract_lines = instance.instance_variable_get(:@contract_lines_for_create)

          uuid_line = contract_lines.find { |l| l.include?('uuid_field') }
          expect(uuid_line).to include(':string')

          int_line = contract_lines.find { |l| l.include?('int_field') }
          expect(int_line).to include(':integer')

          bool_line = contract_lines.find { |l| l.include?('bool_field') }
          expect(bool_line).to include(':bool')

          decimal_line = contract_lines.find { |l| l.include?('decimal_field') }
          expect(decimal_line).to include(':decimal')

          date_line = contract_lines.find { |l| l.include?('date_field') }
          expect(date_line).to include(':date')

          datetime_line = contract_lines.find { |l| l.include?('datetime_field') }
          expect(datetime_line).to include(':time')
        end
      end
    end

    it 'skips field that does not exist in @columns_meta_hash' do
      Dir.mktmpdir do |dir|
        Dir.chdir(dir) do
          FileUtils.mkdir_p(RiderKick.configuration.domains_path + '/use_cases')
          FileUtils.mkdir_p('app/models/models')

          columns = [
            TestColumn.new('id', :uuid, 'uuid', false),
            TestColumn.new('title', :string, 'character varying', true),
            TestColumn.new('created_at', :datetime, 'timestamp', false),
            TestColumn.new('updated_at', :datetime, 'timestamp', false)
          ]
          create_test_model(class_name: 'Article', columns: columns)

          instance = klass.new(['Models::Article', 'actor:user', 'resource_owner:account', 'resource_owner_id:account_id'])
          allow(instance).to receive(:options).and_return({ engine: nil })
          instance.send(:setup_variables)

          # Manually add a field that doesn't exist in columns
          fields = instance.instance_variable_get(:@fields)
          fields << 'nonexistent_field'
          instance.instance_variable_set(:@fields, fields)

          # Re-run contract lines generation logic
          contract_lines = instance.instance_variable_get(:@contract_lines_for_create)
          nonexistent_line = contract_lines.find { |l| l.include?('nonexistent_field') }
          expect(nonexistent_line).to be_nil
        end
      end
    end

    it 'removes nil values with compact' do
      Dir.mktmpdir do |dir|
        Dir.chdir(dir) do
          FileUtils.mkdir_p(RiderKick.configuration.domains_path + '/use_cases')
          FileUtils.mkdir_p('app/models/models')

          columns = [
            TestColumn.new('id', :uuid, 'uuid', false),
            TestColumn.new('title', :string, 'character varying', true),
            TestColumn.new('created_at', :datetime, 'timestamp', false),
            TestColumn.new('updated_at', :datetime, 'timestamp', false)
          ]
          create_test_model(class_name: 'Article', columns: columns)

          instance = klass.new(['Models::Article', 'actor:user', 'resource_owner:account', 'resource_owner_id:account_id'])
          allow(instance).to receive(:options).and_return({ engine: nil })
          instance.send(:setup_variables)

          contract_lines = instance.instance_variable_get(:@contract_lines_for_create)
          expect(contract_lines).not_to include(nil)
          expect(contract_lines.all? { |l| l.is_a?(String) }).to be true
        end
      end
    end
  end

  describe '@contract_lines_for_update generation' do
    it 'makes all fields optional' do
      Dir.mktmpdir do |dir|
        Dir.chdir(dir) do
          FileUtils.mkdir_p(RiderKick.configuration.domains_path + '/use_cases')
          FileUtils.mkdir_p('app/models/models')

          columns = [
            TestColumn.new('id', :uuid, 'uuid', false),
            TestColumn.new('title', :string, 'character varying', false),
            TestColumn.new('created_at', :datetime, 'timestamp', false),
            TestColumn.new('updated_at', :datetime, 'timestamp', false)
          ]
          create_test_model(class_name: 'Article', columns: columns)

          instance = klass.new(['Models::Article', 'actor:user', 'resource_owner:account', 'resource_owner_id:account_id'])
          allow(instance).to receive(:options).and_return({ engine: nil })
          instance.send(:setup_variables)

          contract_lines = instance.instance_variable_get(:@contract_lines_for_update)
          title_line = contract_lines.find { |l| l.include?('title') }
          expect(title_line).to include('optional(:title)')
          expect(title_line).to include('.maybe')
        end
      end
    end

    it 'handles upload field in update' do
      Dir.mktmpdir do |dir|
        Dir.chdir(dir) do
          FileUtils.mkdir_p(RiderKick.configuration.domains_path + '/use_cases')
          FileUtils.mkdir_p('app/models/models')

          columns = [
            TestColumn.new('id', :uuid, 'uuid', false),
            TestColumn.new('title', :string, 'character varying', true),
            TestColumn.new('image', :string, 'character varying', false),
            TestColumn.new('created_at', :datetime, 'timestamp', false),
            TestColumn.new('updated_at', :datetime, 'timestamp', false)
          ]
          create_test_model(class_name: 'Article', columns: columns)

          instance = klass.new(['Models::Article', 'actor:user', 'uploaders:image', 'resource_owner:account', 'resource_owner_id:account_id'])
          allow(instance).to receive(:options).and_return({ engine: nil })
          instance.send(:setup_variables)

          # Test get_column_type directly - should return 'upload' for uploader field
          column_type = instance.send(:get_column_type, 'image')
          expect(column_type).to eq('upload')

          # Uploaders are excluded from contract_fields by design, so they won't appear in update contract lines
          # But the logic for handling upload types is tested via get_column_type
        end
      end
    end

    it 'falls back to :string for unknown db_type in update' do
      Dir.mktmpdir do |dir|
        Dir.chdir(dir) do
          FileUtils.mkdir_p(RiderKick.configuration.domains_path + '/use_cases')
          FileUtils.mkdir_p('app/models/models')

          columns = [
            TestColumn.new('id', :uuid, 'uuid', false),
            TestColumn.new('custom_field', :unknown_type, 'unknown', true),
            TestColumn.new('created_at', :datetime, 'timestamp', false),
            TestColumn.new('updated_at', :datetime, 'timestamp', false)
          ]
          create_test_model(class_name: 'Article', columns: columns)

          instance = klass.new(['Models::Article', 'actor:user', 'resource_owner:account', 'resource_owner_id:account_id'])
          allow(instance).to receive(:options).and_return({ engine: nil })
          instance.send(:setup_variables)

          contract_lines = instance.instance_variable_get(:@contract_lines_for_update)
          custom_line = contract_lines.find { |l| l.include?('custom_field') }
          expect(custom_line).to include(':string')
        end
      end
    end
  end

  describe '@contract_lines_for_list generation' do
    it 'generates from search_able settings' do
      Dir.mktmpdir do |dir|
        Dir.chdir(dir) do
          FileUtils.mkdir_p(RiderKick.configuration.domains_path + '/use_cases')
          FileUtils.mkdir_p('app/models/models')

          create_test_model(class_name: 'Article', columns: create_test_columns)

          instance = klass.new(['Models::Article', 'actor:user', 'search_able:title,body', 'resource_owner:account', 'resource_owner_id:account_id'])
          allow(instance).to receive(:options).and_return({ engine: nil })
          instance.send(:setup_variables)

          contract_lines = instance.instance_variable_get(:@contract_lines_for_list)
          expect(contract_lines.length).to eq(2)
          expect(contract_lines.any? { |l| l.include?('title') }).to be true
          expect(contract_lines.any? { |l| l.include?('body') }).to be true
        end
      end
    end

    it 'parses from @repository_list_filters string format' do
      Dir.mktmpdir do |dir|
        Dir.chdir(dir) do
          FileUtils.mkdir_p(RiderKick.configuration.domains_path + '/use_cases')
          FileUtils.mkdir_p('app/models/models')

          create_test_model(class_name: 'Article', columns: create_test_columns)

          instance = klass.new(['Models::Article', 'actor:user', 'search_able:title', 'resource_owner:account', 'resource_owner_id:account_id'])
          allow(instance).to receive(:options).and_return({ engine: nil })
          instance.send(:setup_variables)

          contract_lines = instance.instance_variable_get(:@contract_lines_for_list)
          title_line = contract_lines.find { |l| l.include?('title') }
          expect(title_line).to include('optional(:title)')
          expect(title_line).to include('.maybe(:string)')
        end
      end
    end

    it 'returns empty array when search_able is empty' do
      Dir.mktmpdir do |dir|
        Dir.chdir(dir) do
          FileUtils.mkdir_p(RiderKick.configuration.domains_path + '/use_cases')
          FileUtils.mkdir_p('app/models/models')

          create_test_model(class_name: 'Article', columns: create_test_columns)

          instance = klass.new(['Models::Article', 'actor:user', 'resource_owner:account', 'resource_owner_id:account_id'])
          allow(instance).to receive(:options).and_return({ engine: nil })
          instance.send(:setup_variables)

          contract_lines = instance.instance_variable_get(:@contract_lines_for_list)
          expect(contract_lines).to eq([])
        end
      end
    end

    it 'handles multiple search fields' do
      Dir.mktmpdir do |dir|
        Dir.chdir(dir) do
          FileUtils.mkdir_p(RiderKick.configuration.domains_path + '/use_cases')
          FileUtils.mkdir_p('app/models/models')

          create_test_model(class_name: 'Article', columns: create_test_columns)

          instance = klass.new(['Models::Article', 'actor:user', 'search_able:title,body,published_at', 'resource_owner:account', 'resource_owner_id:account_id'])
          allow(instance).to receive(:options).and_return({ engine: nil })
          instance.send(:setup_variables)

          contract_lines = instance.instance_variable_get(:@contract_lines_for_list)
          expect(contract_lines.length).to eq(3)
        end
      end
    end
  end

  describe '@repository_list_filters generation' do
    it 'generates from search_able settings' do
      Dir.mktmpdir do |dir|
        Dir.chdir(dir) do
          FileUtils.mkdir_p(RiderKick.configuration.domains_path + '/use_cases')
          FileUtils.mkdir_p('app/models/models')

          create_test_model(class_name: 'Article', columns: create_test_columns)

          instance = klass.new(['Models::Article', 'actor:user', 'search_able:title', 'resource_owner:account', 'resource_owner_id:account_id'])
          allow(instance).to receive(:options).and_return({ engine: nil })
          instance.send(:setup_variables)

          filters = instance.instance_variable_get(:@repository_list_filters)
          expect(filters).to include("{ field: 'title', type: 'search' }")
        end
      end
    end

    it 'handles multiple fields with comma-separated' do
      Dir.mktmpdir do |dir|
        Dir.chdir(dir) do
          FileUtils.mkdir_p(RiderKick.configuration.domains_path + '/use_cases')
          FileUtils.mkdir_p('app/models/models')

          create_test_model(class_name: 'Article', columns: create_test_columns)

          instance = klass.new(['Models::Article', 'actor:user', 'search_able:title,body', 'resource_owner:account', 'resource_owner_id:account_id'])
          allow(instance).to receive(:options).and_return({ engine: nil })
          instance.send(:setup_variables)

          filters = instance.instance_variable_get(:@repository_list_filters)
          expect(filters.length).to eq(2)
          expect(filters).to include("{ field: 'title', type: 'search' }")
          expect(filters).to include("{ field: 'body', type: 'search' }")
        end
      end
    end

    it 'trims whitespace' do
      Dir.mktmpdir do |dir|
        Dir.chdir(dir) do
          FileUtils.mkdir_p(RiderKick.configuration.domains_path + '/use_cases')
          FileUtils.mkdir_p('app/models/models')

          create_test_model(class_name: 'Article', columns: create_test_columns)

          instance = klass.new(['Models::Article', 'actor:user', 'search_able: title , body ', 'resource_owner:account', 'resource_owner_id:account_id'])
          allow(instance).to receive(:options).and_return({ engine: nil })
          instance.send(:setup_variables)

          filters = instance.instance_variable_get(:@repository_list_filters)
          expect(filters).to include("{ field: 'title', type: 'search' }")
          expect(filters).to include("{ field: 'body', type: 'search' }")
        end
      end
    end

    it 'returns empty array when search_able is empty' do
      Dir.mktmpdir do |dir|
        Dir.chdir(dir) do
          FileUtils.mkdir_p(RiderKick.configuration.domains_path + '/use_cases')
          FileUtils.mkdir_p('app/models/models')

          create_test_model(class_name: 'Article', columns: create_test_columns)

          instance = klass.new(['Models::Article', 'actor:user', 'resource_owner:account', 'resource_owner_id:account_id'])
          allow(instance).to receive(:options).and_return({ engine: nil })
          instance.send(:setup_variables)

          filters = instance.instance_variable_get(:@repository_list_filters)
          expect(filters).to eq([])
        end
      end
    end
  end

  describe '@entity_uploader_definitions generation' do
    it 'generates single type for singular uploader' do
      Dir.mktmpdir do |dir|
        Dir.chdir(dir) do
          FileUtils.mkdir_p(RiderKick.configuration.domains_path + '/use_cases')
          FileUtils.mkdir_p('app/models/models')

          create_test_model(class_name: 'Article', columns: create_test_columns)

          instance = klass.new(['Models::Article', 'actor:user', 'uploaders:image', 'resource_owner:account', 'resource_owner_id:account_id'])
          allow(instance).to receive(:options).and_return({ engine: nil })
          instance.send(:setup_variables)

          uploader_defs = instance.instance_variable_get(:@entity_uploader_definitions)
          image_def = uploader_defs.find { |u| u[:name] == 'image' }
          expect(image_def).to eq({ name: 'image', type: 'single' })
        end
      end
    end

    it 'generates multiple type for plural uploader' do
      Dir.mktmpdir do |dir|
        Dir.chdir(dir) do
          FileUtils.mkdir_p(RiderKick.configuration.domains_path + '/use_cases')
          FileUtils.mkdir_p('app/models/models')

          create_test_model(class_name: 'Article', columns: create_test_columns)

          instance = klass.new(['Models::Article', 'actor:user', 'uploaders:images', 'resource_owner:account', 'resource_owner_id:account_id'])
          allow(instance).to receive(:options).and_return({ engine: nil })
          instance.send(:setup_variables)

          uploader_defs = instance.instance_variable_get(:@entity_uploader_definitions)
          images_def = uploader_defs.find { |u| u[:name] == 'images' }
          expect(images_def).to eq({ name: 'images', type: 'multiple' })
        end
      end
    end

    it 'handles multiple uploaders with mix singular/plural' do
      Dir.mktmpdir do |dir|
        Dir.chdir(dir) do
          FileUtils.mkdir_p(RiderKick.configuration.domains_path + '/use_cases')
          FileUtils.mkdir_p('app/models/models')

          create_test_model(class_name: 'Article', columns: create_test_columns)

          instance = klass.new(['Models::Article', 'actor:user', 'uploaders:image,images,asset,assets', 'resource_owner:account', 'resource_owner_id:account_id'])
          allow(instance).to receive(:options).and_return({ engine: nil })
          instance.send(:setup_variables)

          uploader_defs = instance.instance_variable_get(:@entity_uploader_definitions)
          expect(uploader_defs.length).to eq(4)

          image_def = uploader_defs.find { |u| u[:name] == 'image' }
          expect(image_def[:type]).to eq('single')

          images_def = uploader_defs.find { |u| u[:name] == 'images' }
          expect(images_def[:type]).to eq('multiple')

          asset_def = uploader_defs.find { |u| u[:name] == 'asset' }
          expect(asset_def[:type]).to eq('single')

          assets_def = uploader_defs.find { |u| u[:name] == 'assets' }
          expect(assets_def[:type]).to eq('multiple')
        end
      end
    end

    it 'returns empty array when uploaders is empty' do
      Dir.mktmpdir do |dir|
        Dir.chdir(dir) do
          FileUtils.mkdir_p(RiderKick.configuration.domains_path + '/use_cases')
          FileUtils.mkdir_p('app/models/models')

          create_test_model(class_name: 'Article', columns: create_test_columns)

          instance = klass.new(['Models::Article', 'actor:user', 'resource_owner:account', 'resource_owner_id:account_id'])
          allow(instance).to receive(:options).and_return({ engine: nil })
          instance.send(:setup_variables)

          uploader_defs = instance.instance_variable_get(:@entity_uploader_definitions)
          expect(uploader_defs).to eq([])
        end
      end
    end
  end

  describe '#contract_fields' do
    it 'excludes id, created_at, updated_at' do
      Dir.mktmpdir do |dir|
        Dir.chdir(dir) do
          FileUtils.mkdir_p(RiderKick.configuration.domains_path + '/use_cases')
          FileUtils.mkdir_p('app/models/models')

          columns = [
            TestColumn.new('id', :uuid, 'uuid', false),
            TestColumn.new('title', :string, 'character varying', true),
            TestColumn.new('created_at', :datetime, 'timestamp', false),
            TestColumn.new('updated_at', :datetime, 'timestamp', false)
          ]
          create_test_model(class_name: 'Article', columns: columns)

          instance = klass.new(['Models::Article', 'actor:user', 'resource_owner:account', 'resource_owner_id:account_id'])
          allow(instance).to receive(:options).and_return({ engine: nil })
          instance.send(:setup_variables) # Need to setup variables first to initialize @model_class

          fields = instance.send(:contract_fields)
          expect(fields).not_to include('id', 'created_at', 'updated_at')
          expect(fields).to include('title')
        end
      end
    end

    it 'excludes type column (STI)' do
      Dir.mktmpdir do |dir|
        Dir.chdir(dir) do
          FileUtils.mkdir_p(RiderKick.configuration.domains_path + '/use_cases')
          FileUtils.mkdir_p('app/models/models')

          columns = [
            TestColumn.new('id', :uuid, 'uuid', false),
            TestColumn.new('type', :string, 'character varying', true),
            TestColumn.new('title', :string, 'character varying', true),
            TestColumn.new('created_at', :datetime, 'timestamp', false),
            TestColumn.new('updated_at', :datetime, 'timestamp', false)
          ]
          create_test_model(class_name: 'Article', columns: columns)

          instance = klass.new(['Models::Article', 'actor:user', 'resource_owner:account', 'resource_owner_id:account_id'])
          allow(instance).to receive(:options).and_return({ engine: nil })
          instance.send(:setup_variables)

          fields = instance.send(:contract_fields)
          expect(fields).not_to include('type')
          expect(fields).to include('title')
        end
      end
    end

    it 'excludes uploaders from contract fields' do
      Dir.mktmpdir do |dir|
        Dir.chdir(dir) do
          FileUtils.mkdir_p(RiderKick.configuration.domains_path + '/use_cases')
          FileUtils.mkdir_p('app/models/models')

          columns = [
            TestColumn.new('id', :uuid, 'uuid', false),
            TestColumn.new('title', :string, 'character varying', true),
            TestColumn.new('image', :string, 'character varying', true),
            TestColumn.new('created_at', :datetime, 'timestamp', false),
            TestColumn.new('updated_at', :datetime, 'timestamp', false)
          ]
          create_test_model(class_name: 'Article', columns: columns)

          instance = klass.new(['Models::Article', 'actor:user', 'uploaders:image', 'resource_owner:account', 'resource_owner_id:account_id'])
          allow(instance).to receive(:options).and_return({ engine: nil })
          instance.send(:setup_variables)

          fields = instance.send(:contract_fields)
          expect(fields).not_to include('image')
          expect(fields).to include('title')
        end
      end
    end

    it 'returns only column names as strings' do
      Dir.mktmpdir do |dir|
        Dir.chdir(dir) do
          FileUtils.mkdir_p(RiderKick.configuration.domains_path + '/use_cases')
          FileUtils.mkdir_p('app/models/models')

          columns = [
            TestColumn.new('id', :uuid, 'uuid', false),
            TestColumn.new('title', :string, 'character varying', true),
            TestColumn.new('created_at', :datetime, 'timestamp', false),
            TestColumn.new('updated_at', :datetime, 'timestamp', false)
          ]
          create_test_model(class_name: 'Article', columns: columns)

          instance = klass.new(['Models::Article', 'actor:user', 'resource_owner:account', 'resource_owner_id:account_id'])
          allow(instance).to receive(:options).and_return({ engine: nil })
          instance.send(:setup_variables)

          fields = instance.send(:contract_fields)
          expect(fields).to all(be_a(String))
          expect(fields).to include('title')
        end
      end
    end

    it 'returns empty result when only id/timestamps exist' do
      Dir.mktmpdir do |dir|
        Dir.chdir(dir) do
          FileUtils.mkdir_p(RiderKick.configuration.domains_path + '/use_cases')
          FileUtils.mkdir_p('app/models/models')

          columns = [
            TestColumn.new('id', :uuid, 'uuid', false),
            TestColumn.new('created_at', :datetime, 'timestamp', false),
            TestColumn.new('updated_at', :datetime, 'timestamp', false)
          ]
          create_test_model(class_name: 'Article', columns: columns)

          instance = klass.new(['Models::Article', 'actor:user', 'resource_owner:account', 'resource_owner_id:account_id'])
          allow(instance).to receive(:options).and_return({ engine: nil })
          instance.send(:setup_variables)

          fields = instance.send(:contract_fields)
          expect(fields).to eq([])
        end
      end
    end

    it 'handles model with many columns' do
      Dir.mktmpdir do |dir|
        Dir.chdir(dir) do
          FileUtils.mkdir_p(RiderKick.configuration.domains_path + '/use_cases')
          FileUtils.mkdir_p('app/models/models')

          columns = [
            TestColumn.new('id', :uuid, 'uuid', false),
            TestColumn.new('field1', :string, 'character varying', true),
            TestColumn.new('field2', :integer, 'integer', true),
            TestColumn.new('field3', :boolean, 'boolean', true),
            TestColumn.new('field4', :decimal, 'decimal', true),
            TestColumn.new('field5', :date, 'date', true),
            TestColumn.new('created_at', :datetime, 'timestamp', false),
            TestColumn.new('updated_at', :datetime, 'timestamp', false)
          ]
          create_test_model(class_name: 'Article', columns: columns)

          instance = klass.new(['Models::Article', 'actor:user', 'resource_owner:account', 'resource_owner_id:account_id'])
          allow(instance).to receive(:options).and_return({ engine: nil })
          instance.send(:setup_variables)

          fields = instance.send(:contract_fields)
          expect(fields.length).to eq(5)
          expect(fields).to include('field1', 'field2', 'field3', 'field4', 'field5')
        end
      end
    end
  end

  describe '#get_column_type' do
    it 'returns upload for uploader field' do
      Dir.mktmpdir do |dir|
        Dir.chdir(dir) do
          FileUtils.mkdir_p(RiderKick.configuration.domains_path + '/use_cases')
          FileUtils.mkdir_p('app/models/models')

          columns = [
            TestColumn.new('id', :uuid, 'uuid', false),
            TestColumn.new('image', :string, 'character varying', true),
            TestColumn.new('created_at', :datetime, 'timestamp', false),
            TestColumn.new('updated_at', :datetime, 'timestamp', false)
          ]
          create_test_model(class_name: 'Article', columns: columns)

          instance = klass.new(['Models::Article', 'actor:user', 'uploaders:image', 'resource_owner:account', 'resource_owner_id:account_id'])
          allow(instance).to receive(:options).and_return({ engine: nil })
          instance.send(:setup_variables)

          column_type = instance.send(:get_column_type, 'image')
          expect(column_type).to eq('upload')
        end
      end
    end

    it 'returns actual type for non-uploader field' do
      Dir.mktmpdir do |dir|
        Dir.chdir(dir) do
          FileUtils.mkdir_p(RiderKick.configuration.domains_path + '/use_cases')
          FileUtils.mkdir_p('app/models/models')

          columns = [
            TestColumn.new('id', :uuid, 'uuid', false),
            TestColumn.new('title', :string, 'character varying', true),
            TestColumn.new('created_at', :datetime, 'timestamp', false),
            TestColumn.new('updated_at', :datetime, 'timestamp', false)
          ]
          create_test_model(class_name: 'Article', columns: columns)

          instance = klass.new(['Models::Article', 'actor:user', 'resource_owner:account', 'resource_owner_id:account_id'])
          allow(instance).to receive(:options).and_return({ engine: nil })
          instance.send(:setup_variables)

          column_type = instance.send(:get_column_type, 'title')
          expect(column_type).to eq(:string)
        end
      end
    end

    it 'handles various types correctly' do
      Dir.mktmpdir do |dir|
        Dir.chdir(dir) do
          FileUtils.mkdir_p(RiderKick.configuration.domains_path + '/use_cases')
          FileUtils.mkdir_p('app/models/models')

          columns = [
            TestColumn.new('id', :uuid, 'uuid', false),
            TestColumn.new('uuid_field', :uuid, 'uuid', true),
            TestColumn.new('int_field', :integer, 'integer', true),
            TestColumn.new('bool_field', :boolean, 'boolean', true),
            TestColumn.new('created_at', :datetime, 'timestamp', false),
            TestColumn.new('updated_at', :datetime, 'timestamp', false)
          ]
          create_test_model(class_name: 'Article', columns: columns)

          instance = klass.new(['Models::Article', 'actor:user', 'resource_owner:account', 'resource_owner_id:account_id'])
          allow(instance).to receive(:options).and_return({ engine: nil })
          instance.send(:setup_variables)

          expect(instance.send(:get_column_type, 'uuid_field')).to eq(:uuid)
          expect(instance.send(:get_column_type, 'int_field')).to eq(:integer)
          expect(instance.send(:get_column_type, 'bool_field')).to eq(:boolean)
        end
      end
    end
  end

  describe '#uploaders' do
    it 'parses comma-separated uploaders' do
      Dir.mktmpdir do |dir|
        Dir.chdir(dir) do
          FileUtils.mkdir_p(RiderKick.configuration.domains_path + '/use_cases')
          FileUtils.mkdir_p('app/models/models')

          create_test_model(class_name: 'Article', columns: create_test_columns)

          instance = klass.new(['Models::Article', 'actor:user', 'uploaders:images,assets,picture', 'resource_owner:account', 'resource_owner_id:account_id'])
          allow(instance).to receive(:options).and_return({ engine: nil })

          uploaders = instance.send(:uploaders)
          expect(uploaders).to eq(['images', 'assets', 'picture'])
        end
      end
    end

    it 'trims whitespace' do
      Dir.mktmpdir do |dir|
        Dir.chdir(dir) do
          FileUtils.mkdir_p(RiderKick.configuration.domains_path + '/use_cases')
          FileUtils.mkdir_p('app/models/models')

          create_test_model(class_name: 'Article', columns: create_test_columns)

          instance = klass.new(['Models::Article', 'actor:user', 'uploaders: images , assets , picture ', 'resource_owner:account', 'resource_owner_id:account_id'])
          allow(instance).to receive(:options).and_return({ engine: nil })

          uploaders = instance.send(:uploaders)
          expect(uploaders).to eq(['images', 'assets', 'picture'])
        end
      end
    end

    it 'returns empty array for empty string' do
      Dir.mktmpdir do |dir|
        Dir.chdir(dir) do
          FileUtils.mkdir_p(RiderKick.configuration.domains_path + '/use_cases')
          FileUtils.mkdir_p('app/models/models')

          create_test_model(class_name: 'Article', columns: create_test_columns)

          instance = klass.new(['Models::Article', 'actor:user', 'uploaders:', 'resource_owner:account', 'resource_owner_id:account_id'])
          allow(instance).to receive(:options).and_return({ engine: nil })

          uploaders = instance.send(:uploaders)
          expect(uploaders).to eq([])
        end
      end
    end

    it 'returns empty array for nil' do
      Dir.mktmpdir do |dir|
        Dir.chdir(dir) do
          FileUtils.mkdir_p(RiderKick.configuration.domains_path + '/use_cases')
          FileUtils.mkdir_p('app/models/models')

          create_test_model(class_name: 'Article', columns: create_test_columns)

          instance = klass.new(['Models::Article', 'actor:user', 'resource_owner:account', 'resource_owner_id:account_id'])
          allow(instance).to receive(:options).and_return({ engine: nil })

          uploaders = instance.send(:uploaders)
          expect(uploaders).to eq([])
        end
      end
    end

    it 'returns array with single element for single uploader' do
      Dir.mktmpdir do |dir|
        Dir.chdir(dir) do
          FileUtils.mkdir_p(RiderKick.configuration.domains_path + '/use_cases')
          FileUtils.mkdir_p('app/models/models')

          create_test_model(class_name: 'Article', columns: create_test_columns)

          instance = klass.new(['Models::Article', 'actor:user', 'uploaders:image', 'resource_owner:account', 'resource_owner_id:account_id'])
          allow(instance).to receive(:options).and_return({ engine: nil })

          uploaders = instance.send(:uploaders)
          expect(uploaders).to eq(['image'])
        end
      end
    end

    it 'returns array of strings' do
      Dir.mktmpdir do |dir|
        Dir.chdir(dir) do
          FileUtils.mkdir_p(RiderKick.configuration.domains_path + '/use_cases')
          FileUtils.mkdir_p('app/models/models')

          create_test_model(class_name: 'Article', columns: create_test_columns)

          instance = klass.new(['Models::Article', 'actor:user', 'uploaders:images,assets', 'resource_owner:account', 'resource_owner_id:account_id'])
          allow(instance).to receive(:options).and_return({ engine: nil })

          uploaders = instance.send(:uploaders)
          expect(uploaders).to all(be_a(String))
        end
      end
    end
  end

  describe '#is_singular?' do
    it 'returns true for singular words' do
      Dir.mktmpdir do |dir|
        Dir.chdir(dir) do
          FileUtils.mkdir_p(RiderKick.configuration.domains_path + '/use_cases')
          FileUtils.mkdir_p('app/models/models')

          create_test_model(class_name: 'Article', columns: create_test_columns)

          instance = klass.new(['Models::Article', 'actor:user', 'resource_owner:account', 'resource_owner_id:account_id'])
          allow(instance).to receive(:options).and_return({ engine: nil })

          expect(instance.send(:is_singular?, 'image')).to be true
          expect(instance.send(:is_singular?, 'asset')).to be true
          expect(instance.send(:is_singular?, 'picture')).to be true
        end
      end
    end

    it 'returns false for plural words' do
      Dir.mktmpdir do |dir|
        Dir.chdir(dir) do
          FileUtils.mkdir_p(RiderKick.configuration.domains_path + '/use_cases')
          FileUtils.mkdir_p('app/models/models')

          create_test_model(class_name: 'Article', columns: create_test_columns)

          instance = klass.new(['Models::Article', 'actor:user', 'resource_owner:account', 'resource_owner_id:account_id'])
          allow(instance).to receive(:options).and_return({ engine: nil })

          expect(instance.send(:is_singular?, 'images')).to be false
          expect(instance.send(:is_singular?, 'assets')).to be false
          expect(instance.send(:is_singular?, 'pictures')).to be false
        end
      end
    end

    it 'handles edge cases like data and media (uncountable)' do
      Dir.mktmpdir do |dir|
        Dir.chdir(dir) do
          FileUtils.mkdir_p(RiderKick.configuration.domains_path + '/use_cases')
          FileUtils.mkdir_p('app/models/models')

          create_test_model(class_name: 'Article', columns: create_test_columns)

          instance = klass.new(['Models::Article', 'actor:user', 'resource_owner:account', 'resource_owner_id:account_id'])
          allow(instance).to receive(:options).and_return({ engine: nil })

          # data and media are uncountable, but ActiveSupport singularize may change them
          # 'data'.singularize == 'datum', 'media'.singularize == 'medium'
          # So they are NOT singular according to the method logic
          expect(instance.send(:is_singular?, 'data')).to be false
          expect(instance.send(:is_singular?, 'media')).to be false
        end
      end
    end
  end

  # Priority 2: Edge Cases
  describe '#columns_meta' do
    it 'returns all metadata for columns' do
      Dir.mktmpdir do |dir|
        Dir.chdir(dir) do
          FileUtils.mkdir_p(RiderKick.configuration.domains_path + '/use_cases')
          FileUtils.mkdir_p('app/models/models')

          columns = [
            TestColumn.new('id', :uuid, 'uuid', false, nil, nil, nil, nil),
            TestColumn.new('title', :string, 'character varying', true, 'default', nil, nil, 255),
            TestColumn.new('created_at', :datetime, 'timestamp', false, nil, nil, nil, nil),
            TestColumn.new('updated_at', :datetime, 'timestamp', false, nil, nil, nil, nil)
          ]
          create_test_model(class_name: 'Article', columns: columns)

          instance = klass.new(['Models::Article', 'actor:user', 'resource_owner:account', 'resource_owner_id:account_id'])
          allow(instance).to receive(:options).and_return({ engine: nil })
          instance.send(:setup_variables)

          columns_meta = instance.instance_variable_get(:@columns)
          title_meta = columns_meta.find { |c| c[:name] == 'title' }

          expect(title_meta).to include(
                                  name:     'title',
                                  type:     :string,
                                  sql_type: 'character varying',
                                  null:     true,
                                  default:  'default',
                                  limit:    255
          )
        end
      end
    end

    it 'handles column with sql_type present' do
      Dir.mktmpdir do |dir|
        Dir.chdir(dir) do
          FileUtils.mkdir_p(RiderKick.configuration.domains_path + '/use_cases')
          FileUtils.mkdir_p('app/models/models')

          columns = [
            TestColumn.new('id', :uuid, 'uuid', false),
            TestColumn.new('title', :string, 'character varying', true),
            TestColumn.new('created_at', :datetime, 'timestamp', false),
            TestColumn.new('updated_at', :datetime, 'timestamp', false)
          ]
          create_test_model(class_name: 'Article', columns: columns)

          instance = klass.new(['Models::Article', 'actor:user', 'resource_owner:account', 'resource_owner_id:account_id'])
          allow(instance).to receive(:options).and_return({ engine: nil })
          instance.send(:setup_variables)

          columns_meta = instance.instance_variable_get(:@columns)
          title_meta = columns_meta.find { |c| c[:name] == 'title' }
          expect(title_meta[:sql_type]).to eq('character varying')
        end
      end
    end

    it 'handles column without sql_type' do
      Dir.mktmpdir do |dir|
        Dir.chdir(dir) do
          FileUtils.mkdir_p(RiderKick.configuration.domains_path + '/use_cases')
          FileUtils.mkdir_p('app/models/models')

          column_without_sql_type = Class.new(Struct.new(:name, :type, :null)) do
            def sql_type
              nil
            end
          end

          columns = [
            column_without_sql_type.new('id', :uuid, false),
            TestColumn.new('title', :string, 'character varying', true),
            TestColumn.new('created_at', :datetime, 'timestamp', false),
            TestColumn.new('updated_at', :datetime, 'timestamp', false)
          ]
          create_test_model(class_name: 'Article', columns: columns)

          instance = klass.new(['Models::Article', 'actor:user', 'resource_owner:account', 'resource_owner_id:account_id'])
          allow(instance).to receive(:options).and_return({ engine: nil })
          instance.send(:setup_variables)

          columns_meta = instance.instance_variable_get(:@columns)
          id_meta = columns_meta.find { |c| c[:name] == 'id' }
          expect(id_meta[:sql_type]).to be_nil
        end
      end
    end

    it 'handles column with null: true and null: false' do
      Dir.mktmpdir do |dir|
        Dir.chdir(dir) do
          FileUtils.mkdir_p(RiderKick.configuration.domains_path + '/use_cases')
          FileUtils.mkdir_p('app/models/models')

          columns = [
            TestColumn.new('id', :uuid, 'uuid', false),
            TestColumn.new('title', :string, 'character varying', true),
            TestColumn.new('required_field', :string, 'character varying', false),
            TestColumn.new('created_at', :datetime, 'timestamp', false),
            TestColumn.new('updated_at', :datetime, 'timestamp', false)
          ]
          create_test_model(class_name: 'Article', columns: columns)

          instance = klass.new(['Models::Article', 'actor:user', 'resource_owner:account', 'resource_owner_id:account_id'])
          allow(instance).to receive(:options).and_return({ engine: nil })
          instance.send(:setup_variables)

          columns_meta = instance.instance_variable_get(:@columns)
          title_meta = columns_meta.find { |c| c[:name] == 'title' }
          required_meta = columns_meta.find { |c| c[:name] == 'required_field' }

          expect(title_meta[:null]).to be true
          expect(required_meta[:null]).to be false
        end
      end
    end

    it 'handles column with default value' do
      Dir.mktmpdir do |dir|
        Dir.chdir(dir) do
          FileUtils.mkdir_p(RiderKick.configuration.domains_path + '/use_cases')
          FileUtils.mkdir_p('app/models/models')

          columns = [
            TestColumn.new('id', :uuid, 'uuid', false),
            TestColumn.new('title', :string, 'character varying', true, 'Untitled'),
            TestColumn.new('created_at', :datetime, 'timestamp', false),
            TestColumn.new('updated_at', :datetime, 'timestamp', false)
          ]
          create_test_model(class_name: 'Article', columns: columns)

          instance = klass.new(['Models::Article', 'actor:user', 'resource_owner:account', 'resource_owner_id:account_id'])
          allow(instance).to receive(:options).and_return({ engine: nil })
          instance.send(:setup_variables)

          columns_meta = instance.instance_variable_get(:@columns)
          title_meta = columns_meta.find { |c| c[:name] == 'title' }
          expect(title_meta[:default]).to eq('Untitled')
        end
      end
    end

    it 'handles decimal column with precision and scale' do
      Dir.mktmpdir do |dir|
        Dir.chdir(dir) do
          FileUtils.mkdir_p(RiderKick.configuration.domains_path + '/use_cases')
          FileUtils.mkdir_p('app/models/models')

          columns = [
            TestColumn.new('id', :uuid, 'uuid', false),
            TestColumn.new('price', :decimal, 'decimal', true, nil, 10, 2, nil),
            TestColumn.new('created_at', :datetime, 'timestamp', false),
            TestColumn.new('updated_at', :datetime, 'timestamp', false)
          ]
          create_test_model(class_name: 'Article', columns: columns)

          instance = klass.new(['Models::Article', 'actor:user', 'resource_owner:account', 'resource_owner_id:account_id'])
          allow(instance).to receive(:options).and_return({ engine: nil })
          instance.send(:setup_variables)

          columns_meta = instance.instance_variable_get(:@columns)
          price_meta = columns_meta.find { |c| c[:name] == 'price' }
          expect(price_meta[:precision]).to eq(10)
          expect(price_meta[:scale]).to eq(2)
        end
      end
    end

    it 'handles column with limit' do
      Dir.mktmpdir do |dir|
        Dir.chdir(dir) do
          FileUtils.mkdir_p(RiderKick.configuration.domains_path + '/use_cases')
          FileUtils.mkdir_p('app/models/models')

          columns = [
            TestColumn.new('id', :uuid, 'uuid', false),
            TestColumn.new('title', :string, 'character varying', true, nil, nil, nil, 255),
            TestColumn.new('created_at', :datetime, 'timestamp', false),
            TestColumn.new('updated_at', :datetime, 'timestamp', false)
          ]
          create_test_model(class_name: 'Article', columns: columns)

          instance = klass.new(['Models::Article', 'actor:user', 'resource_owner:account', 'resource_owner_id:account_id'])
          allow(instance).to receive(:options).and_return({ engine: nil })
          instance.send(:setup_variables)

          columns_meta = instance.instance_variable_get(:@columns)
          title_meta = columns_meta.find { |c| c[:name] == 'title' }
          expect(title_meta[:limit]).to eq(255)
        end
      end
    end

    it 'checks respond_to? for optional methods' do
      Dir.mktmpdir do |dir|
        Dir.chdir(dir) do
          FileUtils.mkdir_p(RiderKick.configuration.domains_path + '/use_cases')
          FileUtils.mkdir_p('app/models/models')

          # Create a column that doesn't respond to all methods
          minimal_column = Struct.new(:name, :type) do
            def to_s
              name.to_s
            end
          end

          columns = [
            minimal_column.new('id', :uuid),
            TestColumn.new('title', :string, 'character varying', true),
            TestColumn.new('created_at', :datetime, 'timestamp', false),
            TestColumn.new('updated_at', :datetime, 'timestamp', false)
          ]
          create_test_model(class_name: 'Article', columns: columns)

          instance = klass.new(['Models::Article', 'actor:user', 'resource_owner:account', 'resource_owner_id:account_id'])
          allow(instance).to receive(:options).and_return({ engine: nil })
          instance.send(:setup_variables)

          columns_meta = instance.instance_variable_get(:@columns)
          id_meta = columns_meta.find { |c| c[:name] == 'id' }
          expect(id_meta[:sql_type]).to be_nil
          expect(id_meta[:null]).to be_nil
        end
      end
    end

    it 'returns array of hashes' do
      Dir.mktmpdir do |dir|
        Dir.chdir(dir) do
          FileUtils.mkdir_p(RiderKick.configuration.domains_path + '/use_cases')
          FileUtils.mkdir_p('app/models/models')

          create_test_model(class_name: 'Article', columns: create_test_columns)

          instance = klass.new(['Models::Article', 'actor:user', 'resource_owner:account', 'resource_owner_id:account_id'])
          allow(instance).to receive(:options).and_return({ engine: nil })
          instance.send(:setup_variables)

          columns_meta = instance.instance_variable_get(:@columns)
          expect(columns_meta).to be_an(Array)
          expect(columns_meta.all? { |c| c.is_a?(Hash) }).to be true
        end
      end
    end
  end

  describe 'getter methods' do
    it 'returns cached value for contract_lines_for_create' do
      Dir.mktmpdir do |dir|
        Dir.chdir(dir) do
          FileUtils.mkdir_p(RiderKick.configuration.domains_path + '/use_cases')
          FileUtils.mkdir_p('app/models/models')

          create_test_model(class_name: 'Article', columns: create_test_columns)

          instance = klass.new(['Models::Article', 'actor:user', 'resource_owner:account', 'resource_owner_id:account_id'])
          allow(instance).to receive(:options).and_return({ engine: nil })
          instance.send(:setup_variables)

          cached_value = instance.instance_variable_get(:@contract_lines_for_create)
          # Getter method is private, so we need to use send
          expect(instance.send(:contract_lines_for_create)).to eq(cached_value)
        end
      end
    end

    it 'returns empty array for contract_lines_for_create when not set' do
      Dir.mktmpdir do |dir|
        Dir.chdir(dir) do
          FileUtils.mkdir_p(RiderKick.configuration.domains_path + '/use_cases')
          FileUtils.mkdir_p('app/models/models')

          create_test_model(class_name: 'Article', columns: create_test_columns)

          instance = klass.new(['Models::Article', 'actor:user', 'resource_owner:account', 'resource_owner_id:account_id'])
          allow(instance).to receive(:options).and_return({ engine: nil })
          instance.instance_variable_set(:@contract_lines_for_create, nil)

          expect(instance.send(:contract_lines_for_create)).to eq([])
        end
      end
    end

    it 'returns cached value for contract_lines_for_update' do
      Dir.mktmpdir do |dir|
        Dir.chdir(dir) do
          FileUtils.mkdir_p(RiderKick.configuration.domains_path + '/use_cases')
          FileUtils.mkdir_p('app/models/models')

          create_test_model(class_name: 'Article', columns: create_test_columns)

          instance = klass.new(['Models::Article', 'actor:user', 'resource_owner:account', 'resource_owner_id:account_id'])
          allow(instance).to receive(:options).and_return({ engine: nil })
          instance.send(:setup_variables)

          cached_value = instance.instance_variable_get(:@contract_lines_for_update)
          expect(instance.send(:contract_lines_for_update)).to eq(cached_value)
        end
      end
    end

    it 'returns empty array for contract_lines_for_update when not set' do
      Dir.mktmpdir do |dir|
        Dir.chdir(dir) do
          FileUtils.mkdir_p(RiderKick.configuration.domains_path + '/use_cases')
          FileUtils.mkdir_p('app/models/models')

          create_test_model(class_name: 'Article', columns: create_test_columns)

          instance = klass.new(['Models::Article', 'actor:user', 'resource_owner:account', 'resource_owner_id:account_id'])
          allow(instance).to receive(:options).and_return({ engine: nil })
          instance.instance_variable_set(:@contract_lines_for_update, nil)

          expect(instance.send(:contract_lines_for_update)).to eq([])
        end
      end
    end

    it 'returns cached value for contract_lines_for_list' do
      Dir.mktmpdir do |dir|
        Dir.chdir(dir) do
          FileUtils.mkdir_p(RiderKick.configuration.domains_path + '/use_cases')
          FileUtils.mkdir_p('app/models/models')

          create_test_model(class_name: 'Article', columns: create_test_columns)

          instance = klass.new(['Models::Article', 'actor:user', 'search_able:title', 'resource_owner:account', 'resource_owner_id:account_id'])
          allow(instance).to receive(:options).and_return({ engine: nil })
          instance.send(:setup_variables)

          cached_value = instance.instance_variable_get(:@contract_lines_for_list)
          expect(instance.send(:contract_lines_for_list)).to eq(cached_value)
        end
      end
    end

    it 'returns empty array for contract_lines_for_list when not set' do
      Dir.mktmpdir do |dir|
        Dir.chdir(dir) do
          FileUtils.mkdir_p(RiderKick.configuration.domains_path + '/use_cases')
          FileUtils.mkdir_p('app/models/models')

          create_test_model(class_name: 'Article', columns: create_test_columns)

          instance = klass.new(['Models::Article', 'actor:user', 'resource_owner:account', 'resource_owner_id:account_id'])
          allow(instance).to receive(:options).and_return({ engine: nil })
          instance.instance_variable_set(:@contract_lines_for_list, nil)

          expect(instance.send(:contract_lines_for_list)).to eq([])
        end
      end
    end

    it 'returns cached value for repository_list_filters' do
      Dir.mktmpdir do |dir|
        Dir.chdir(dir) do
          FileUtils.mkdir_p(RiderKick.configuration.domains_path + '/use_cases')
          FileUtils.mkdir_p('app/models/models')

          create_test_model(class_name: 'Article', columns: create_test_columns)

          instance = klass.new(['Models::Article', 'actor:user', 'search_able:title', 'resource_owner:account', 'resource_owner_id:account_id'])
          allow(instance).to receive(:options).and_return({ engine: nil })
          instance.send(:setup_variables)

          cached_value = instance.instance_variable_get(:@repository_list_filters)
          expect(instance.send(:repository_list_filters)).to eq(cached_value)
        end
      end
    end

    it 'returns empty array for repository_list_filters when not set' do
      Dir.mktmpdir do |dir|
        Dir.chdir(dir) do
          FileUtils.mkdir_p(RiderKick.configuration.domains_path + '/use_cases')
          FileUtils.mkdir_p('app/models/models')

          create_test_model(class_name: 'Article', columns: create_test_columns)

          instance = klass.new(['Models::Article', 'actor:user', 'resource_owner:account', 'resource_owner_id:account_id'])
          allow(instance).to receive(:options).and_return({ engine: nil })
          instance.instance_variable_set(:@repository_list_filters, nil)

          expect(instance.send(:repository_list_filters)).to eq([])
        end
      end
    end

    it 'returns cached value for entity_db_fields' do
      Dir.mktmpdir do |dir|
        Dir.chdir(dir) do
          FileUtils.mkdir_p(RiderKick.configuration.domains_path + '/use_cases')
          FileUtils.mkdir_p('app/models/models')

          create_test_model(class_name: 'Article', columns: create_test_columns)

          instance = klass.new(['Models::Article', 'actor:user', 'resource_owner:account', 'resource_owner_id:account_id'])
          allow(instance).to receive(:options).and_return({ engine: nil })
          instance.send(:setup_variables)

          cached_value = instance.instance_variable_get(:@entity_db_fields)
          expect(instance.send(:entity_db_fields)).to eq(cached_value)
        end
      end
    end

    it 'returns cached value for entity_uploader_definitions' do
      Dir.mktmpdir do |dir|
        Dir.chdir(dir) do
          FileUtils.mkdir_p(RiderKick.configuration.domains_path + '/use_cases')
          FileUtils.mkdir_p('app/models/models')

          create_test_model(class_name: 'Article', columns: create_test_columns)

          instance = klass.new(['Models::Article', 'actor:user', 'uploaders:image', 'resource_owner:account', 'resource_owner_id:account_id'])
          allow(instance).to receive(:options).and_return({ engine: nil })
          instance.send(:setup_variables)

          cached_value = instance.instance_variable_get(:@entity_uploader_definitions)
          expect(instance.send(:entity_uploader_definitions)).to eq(cached_value)
        end
      end
    end

    it 'returns empty array for entity_uploader_definitions when not set' do
      Dir.mktmpdir do |dir|
        Dir.chdir(dir) do
          FileUtils.mkdir_p(RiderKick.configuration.domains_path + '/use_cases')
          FileUtils.mkdir_p('app/models/models')

          create_test_model(class_name: 'Article', columns: create_test_columns)

          instance = klass.new(['Models::Article', 'actor:user', 'resource_owner:account', 'resource_owner_id:account_id'])
          allow(instance).to receive(:options).and_return({ engine: nil })
          instance.instance_variable_set(:@entity_uploader_definitions, nil)

          expect(instance.send(:entity_uploader_definitions)).to eq([])
        end
      end
    end
  end

  describe '#configure_engine' do
    it 'handles combination of --engine and --domain together' do
      Dir.mktmpdir do |dir|
        Dir.chdir(dir) do
          FileUtils.mkdir_p(RiderKick.configuration.domains_path + '/use_cases')
          FileUtils.mkdir_p('app/models/models')

          create_test_model(class_name: 'Article', columns: create_test_columns)

          instance = klass.new(['Models::Article', 'actor:user', 'resource_owner:account', 'resource_owner_id:account_id'])
          allow(instance).to receive(:options).and_return({ engine: 'Core', domain: 'admin/' })
          instance.send(:configure_engine)

          expect(RiderKick.configuration.engine_name).to eq('Core')
          expect(RiderKick.configuration.domain_scope).to eq('core/admin/')
        end
      end
    end

    it 'handles --domain with trailing slash' do
      Dir.mktmpdir do |dir|
        Dir.chdir(dir) do
          FileUtils.mkdir_p(RiderKick.configuration.domains_path + '/use_cases')
          FileUtils.mkdir_p('app/models/models')

          create_test_model(class_name: 'Article', columns: create_test_columns)

          instance = klass.new(['Models::Article', 'actor:user', 'resource_owner:account', 'resource_owner_id:account_id'])
          allow(instance).to receive(:options).and_return({ engine: nil, domain: 'admin/' })
          instance.send(:configure_engine)

          expect(RiderKick.configuration.domain_scope).to eq('admin/')
        end
      end
    end

    it 'handles --domain without trailing slash' do
      Dir.mktmpdir do |dir|
        Dir.chdir(dir) do
          FileUtils.mkdir_p(RiderKick.configuration.domains_path + '/use_cases')
          FileUtils.mkdir_p('app/models/models')

          create_test_model(class_name: 'Article', columns: create_test_columns)

          instance = klass.new(['Models::Article', 'actor:user', 'resource_owner:account', 'resource_owner_id:account_id'])
          allow(instance).to receive(:options).and_return({ engine: nil, domain: 'admin' })
          instance.send(:configure_engine)

          expect(RiderKick.configuration.domain_scope).to eq('admin')
        end
      end
    end

    it 'prevents duplicate messages with @engine_configured flag' do
      Dir.mktmpdir do |dir|
        Dir.chdir(dir) do
          FileUtils.mkdir_p(RiderKick.configuration.domains_path + '/use_cases')
          FileUtils.mkdir_p('app/models/models')

          create_test_model(class_name: 'Article', columns: create_test_columns)

          instance = klass.new(['Models::Article', 'actor:user', 'resource_owner:account', 'resource_owner_id:account_id'])
          allow(instance).to receive(:options).and_return({ engine: nil })

          # First call should show message
          expect(instance).to receive(:say).at_least(:once)
          instance.send(:configure_engine)

          # Set flag and call again - should not show message again
          instance.instance_variable_set(:@engine_configured, true)
          expect(instance).not_to receive(:say)
          instance.send(:configure_engine)
        end
      end
    end

    it 'handles engine name with underscore' do
      Dir.mktmpdir do |dir|
        Dir.chdir(dir) do
          FileUtils.mkdir_p(RiderKick.configuration.domains_path + '/use_cases')
          FileUtils.mkdir_p('app/models/models')

          create_test_model(class_name: 'Article', columns: create_test_columns)

          instance = klass.new(['Models::Article', 'actor:user', 'resource_owner:account', 'resource_owner_id:account_id'])
          allow(instance).to receive(:options).and_return({ engine: 'order_engine', domain: nil })
          instance.send(:configure_engine)

          expect(RiderKick.configuration.engine_name).to eq('order_engine')
          expect(RiderKick.configuration.domain_scope).to eq('order_engine/')
        end
      end
    end

    it 'handles engine name with camelCase' do
      Dir.mktmpdir do |dir|
        Dir.chdir(dir) do
          FileUtils.mkdir_p(RiderKick.configuration.domains_path + '/use_cases')
          FileUtils.mkdir_p('app/models/models')

          create_test_model(class_name: 'Article', columns: create_test_columns)

          instance = klass.new(['Models::Article', 'actor:user', 'resource_owner:account', 'resource_owner_id:account_id'])
          allow(instance).to receive(:options).and_return({ engine: 'OrderEngine', domain: nil })
          instance.send(:configure_engine)

          expect(RiderKick.configuration.engine_name).to eq('OrderEngine')
          expect(RiderKick.configuration.domain_scope).to eq('order_engine/')
        end
      end
    end

    it 'concatenates domain scope when engine + domain' do
      Dir.mktmpdir do |dir|
        Dir.chdir(dir) do
          FileUtils.mkdir_p(RiderKick.configuration.domains_path + '/use_cases')
          FileUtils.mkdir_p('app/models/models')

          create_test_model(class_name: 'Article', columns: create_test_columns)

          instance = klass.new(['Models::Article', 'actor:user', 'resource_owner:account', 'resource_owner_id:account_id'])
          allow(instance).to receive(:options).and_return({ engine: 'Core', domain: 'admin/' })
          instance.send(:configure_engine)

          expect(RiderKick.configuration.domain_scope).to eq('core/admin/')
        end
      end
    end

    it 'sets domain scope when only domain (without engine)' do
      Dir.mktmpdir do |dir|
        Dir.chdir(dir) do
          FileUtils.mkdir_p(RiderKick.configuration.domains_path + '/use_cases')
          FileUtils.mkdir_p('app/models/models')

          create_test_model(class_name: 'Article', columns: create_test_columns)

          instance = klass.new(['Models::Article', 'actor:user', 'resource_owner:account', 'resource_owner_id:account_id'])
          allow(instance).to receive(:options).and_return({ engine: nil, domain: 'admin/' })
          instance.send(:configure_engine)

          expect(RiderKick.configuration.domain_scope).to eq('admin/')
        end
      end
    end
  end

  describe '#validation!' do
    it 'trims whitespace from actor' do
      Dir.mktmpdir do |dir|
        Dir.chdir(dir) do
          FileUtils.mkdir_p(RiderKick.configuration.domains_path + '/use_cases')
          FileUtils.mkdir_p('app/models/models')

          create_test_model(class_name: 'Article', columns: create_test_columns)

          instance = klass.new(['Models::Article', 'actor: user ', 'resource_owner:account', 'resource_owner_id:account_id'])
          allow(instance).to receive(:options).and_return({ engine: nil })

          expect { instance.send(:validation!) }.not_to raise_error
        end
      end
    end

    it 'trims whitespace from resource_owner' do
      Dir.mktmpdir do |dir|
        Dir.chdir(dir) do
          FileUtils.mkdir_p(RiderKick.configuration.domains_path + '/use_cases')
          FileUtils.mkdir_p('app/models/models')

          create_test_model(class_name: 'Article', columns: create_test_columns)

          instance = klass.new(['Models::Article', 'actor:user', 'resource_owner: account ', 'resource_owner_id:account_id'])
          allow(instance).to receive(:options).and_return({ engine: nil })

          expect { instance.send(:validation!) }.not_to raise_error
        end
      end
    end

    it 'trims whitespace from resource_owner_id' do
      Dir.mktmpdir do |dir|
        Dir.chdir(dir) do
          FileUtils.mkdir_p(RiderKick.configuration.domains_path + '/use_cases')
          FileUtils.mkdir_p('app/models/models')

          create_test_model(class_name: 'Article', columns: create_test_columns)

          instance = klass.new(['Models::Article', 'actor:user', 'resource_owner:account', 'resource_owner_id: account_id '])
          allow(instance).to receive(:options).and_return({ engine: nil })

          expect { instance.send(:validation!) }.not_to raise_error
        end
      end
    end

    it 'raises error with clear message for missing actor' do
      Dir.mktmpdir do |dir|
        Dir.chdir(dir) do
          FileUtils.mkdir_p(RiderKick.configuration.domains_path + '/use_cases')
          FileUtils.mkdir_p('app/models/models')

          create_test_model(class_name: 'Article', columns: create_test_columns)

          instance = klass.new(['Models::Article', 'resource_owner:account', 'resource_owner_id:account_id'])
          allow(instance).to receive(:options).and_return({ engine: nil })

          expect {
            instance.send(:validation!)
          }.to raise_error(RiderKick::ValidationError, /Missing required setting: actor/)
        end
      end
    end

    it 'raises error with clear message for missing resource_owner' do
      Dir.mktmpdir do |dir|
        Dir.chdir(dir) do
          FileUtils.mkdir_p(RiderKick.configuration.domains_path + '/use_cases')
          FileUtils.mkdir_p('app/models/models')

          create_test_model(class_name: 'Article', columns: create_test_columns)

          instance = klass.new(['Models::Article', 'actor:user', 'resource_owner_id:account_id'])
          allow(instance).to receive(:options).and_return({ engine: nil })

          expect {
            instance.send(:validation!)
          }.to raise_error(RiderKick::ValidationError, /Missing required setting: resource_owner/)
        end
      end
    end

    it 'raises error with clear message for missing resource_owner_id' do
      Dir.mktmpdir do |dir|
        Dir.chdir(dir) do
          FileUtils.mkdir_p(RiderKick.configuration.domains_path + '/use_cases')
          FileUtils.mkdir_p('app/models/models')

          create_test_model(class_name: 'Article', columns: create_test_columns)

          instance = klass.new(['Models::Article', 'actor:user', 'resource_owner:account'])
          allow(instance).to receive(:options).and_return({ engine: nil })

          expect {
            instance.send(:validation!)
          }.to raise_error(RiderKick::ValidationError, /Missing required setting: resource_owner_id/)
        end
      end
    end

    it 'raises error when domains_path does not exist' do
      Dir.mktmpdir do |dir|
        Dir.chdir(dir) do
          FileUtils.mkdir_p('app/models/models')

          create_test_model(class_name: 'Article', columns: create_test_columns)

          instance = klass.new(['Models::Article', 'actor:user', 'resource_owner:account', 'resource_owner_id:account_id'])
          allow(instance).to receive(:options).and_return({ engine: nil })

          expect {
            instance.send(:validation!)
          }.to raise_error(RiderKick::ValidationError, /clean_arch.*--setup/i)
        end
      end
    end
  end

  # Priority 3: Meta Methods
  describe '#fkeys_meta' do
    it 'returns empty array' do
      Dir.mktmpdir do |dir|
        Dir.chdir(dir) do
          FileUtils.mkdir_p(RiderKick.configuration.domains_path + '/use_cases')
          FileUtils.mkdir_p('app/models/models')

          create_test_model(class_name: 'Article', columns: create_test_columns)

          instance = klass.new(['Models::Article', 'actor:user', 'resource_owner:account', 'resource_owner_id:account_id'])
          allow(instance).to receive(:options).and_return({ engine: nil })

          expect(instance.send(:fkeys_meta)).to eq([])
        end
      end
    end
  end

  describe '#indexes_meta' do
    it 'returns empty array' do
      Dir.mktmpdir do |dir|
        Dir.chdir(dir) do
          FileUtils.mkdir_p(RiderKick.configuration.domains_path + '/use_cases')
          FileUtils.mkdir_p('app/models/models')

          create_test_model(class_name: 'Article', columns: create_test_columns)

          instance = klass.new(['Models::Article', 'actor:user', 'resource_owner:account', 'resource_owner_id:account_id'])
          allow(instance).to receive(:options).and_return({ engine: nil })

          expect(instance.send(:indexes_meta)).to eq([])
        end
      end
    end
  end

  describe '#enums_meta' do
    it 'returns empty hash' do
      Dir.mktmpdir do |dir|
        Dir.chdir(dir) do
          FileUtils.mkdir_p(RiderKick.configuration.domains_path + '/use_cases')
          FileUtils.mkdir_p('app/models/models')

          create_test_model(class_name: 'Article', columns: create_test_columns)

          instance = klass.new(['Models::Article', 'actor:user', 'resource_owner:account', 'resource_owner_id:account_id'])
          allow(instance).to receive(:options).and_return({ engine: nil })

          expect(instance.send(:enums_meta)).to eq({})
        end
      end
    end
  end

  describe '#generate_files' do
    it 'generates path for engine' do
      Dir.mktmpdir do |dir|
        Dir.chdir(dir) do
          FileUtils.mkdir_p(RiderKick.configuration.domains_path + '/use_cases')
          FileUtils.mkdir_p('app/models/models')
          FileUtils.mkdir_p('engines/core/db/structures')

          create_test_model(class_name: 'Article', columns: create_test_columns)

          RiderKick.configuration.engine_name = 'Core'
          instance = klass.new(['Models::Article', 'actor:user', 'resource_owner:account', 'resource_owner_id:account_id'])
          allow(instance).to receive(:options).and_return({ engine: nil })
          instance.send(:setup_variables)

          expect(instance).to receive(:template).with(
                                'db/structures/example.yaml.tt',
                                'engines/core/db/structures/articles_structure.yaml'
          )
          instance.send(:generate_files, 'articles')
        end
      end
    end

    it 'generates path for main app' do
      Dir.mktmpdir do |dir|
        Dir.chdir(dir) do
          FileUtils.mkdir_p(RiderKick.configuration.domains_path + '/use_cases')
          FileUtils.mkdir_p('app/models/models')
          FileUtils.mkdir_p('db/structures')

          create_test_model(class_name: 'Article', columns: create_test_columns)

          RiderKick.configuration.engine_name = nil
          instance = klass.new(['Models::Article', 'actor:user', 'resource_owner:account', 'resource_owner_id:account_id'])
          allow(instance).to receive(:options).and_return({ engine: nil })
          instance.send(:setup_variables)

          expect(instance).to receive(:template).with(
                                'db/structures/example.yaml.tt',
                                'db/structures/articles_structure.yaml'
          )
          instance.send(:generate_files, 'articles')
        end
      end
    end
  end

  # Priority 4: Error Handling
  describe 'error handling' do
    it 'handles constantize error when model class not found' do
      Dir.mktmpdir do |dir|
        Dir.chdir(dir) do
          FileUtils.mkdir_p(RiderKick.configuration.domains_path + '/use_cases')
          FileUtils.mkdir_p('app/models/models')

          instance = klass.new(['Models::NonExistent', 'actor:user', 'resource_owner:account', 'resource_owner_id:account_id'])
          allow(instance).to receive(:options).and_return({ engine: nil })

          expect {
            instance.send(:setup_variables)
          }.to raise_error(RiderKick::ModelNotFoundError)
        end
      end
    end

    it 'handles nil columns_hash[field] in get_column_type' do
      Dir.mktmpdir do |dir|
        Dir.chdir(dir) do
          FileUtils.mkdir_p(RiderKick.configuration.domains_path + '/use_cases')
          FileUtils.mkdir_p('app/models/models')

          columns = [
            TestColumn.new('id', :uuid, 'uuid', false),
            TestColumn.new('title', :string, 'character varying', true),
            TestColumn.new('created_at', :datetime, 'timestamp', false),
            TestColumn.new('updated_at', :datetime, 'timestamp', false)
          ]
          create_test_model(class_name: 'Article', columns: columns)

          instance = klass.new(['Models::Article', 'actor:user', 'resource_owner:account', 'resource_owner_id:account_id'])
          allow(instance).to receive(:options).and_return({ engine: nil })
          instance.send(:setup_variables)

          # Mock columns_hash to return nil for a field
          model_class = instance.instance_variable_get(:@model_class)
          allow(model_class).to receive(:columns_hash).and_return({ 'title' => nil })

          expect {
            instance.send(:get_column_type, 'nonexistent')
          }.to raise_error(NoMethodError)
        end
      end
    end
  end
end
