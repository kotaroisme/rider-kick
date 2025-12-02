# frozen_string_literal: true

require 'rails/generators'
require 'tmpdir'
require 'fileutils'
require 'generators/rider_kick/scaffold_generator'

RSpec.describe 'rider_kick:scaffold conditional filtering' do
  let(:klass) { RiderKick::ScaffoldGenerator }

  # Helper untuk setup test model (mirip dengan scaffold_generator_success_spec.rb)
  def setup_test_model(class_name: 'Article', columns: [])
    Object.send(:remove_const, :Models) if Object.const_defined?(:Models)
    Object.send(:remove_const, :TestColumn) if Object.const_defined?(:TestColumn)

    # Create Models module using Module.new to avoid syntax error
    models_module = Module.new
    Object.const_set(:Models, models_module)

    # Create TestColumn struct
    test_column_struct = Struct.new(:name, :type, :sql_type, :null, :default, :precision, :scale, :limit)
    Object.const_set(:TestColumn, test_column_struct)

    # Remove existing class if it exists
    model_class_name = "Models::#{class_name}"
    if Object.const_defined?(model_class_name)
      parts = model_class_name.split('::')
      if parts.length > 1
        parent = Object.const_get(parts[0..-2].join('::'))
        parent.send(:remove_const, parts.last.to_sym) if parent.const_defined?(parts.last.to_sym)
      end
    end

    # Create model class directly (like in scaffold_generator_success_spec.rb)
    model_class = Class.new do
      define_singleton_method(:columns) { columns }
      define_singleton_method(:columns_hash) do
        columns.to_h { |c| [c.name.to_s, Struct.new(:type).new(c.type)] }
      end
      define_singleton_method(:column_names) { columns.map { |c| c.name.to_s } }
    end

    Models.const_set(class_name, model_class)
    created_class = Models.const_get(class_name)

    # Verify that constantize works (this is what validate_model_exists! will do)
    model_class_name.constantize

    created_class
  end

  describe 'field_exists_in_contract? method' do
    it 'returns true when field exists in contract as required' do
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

          setup_test_model(class_name: 'Article', columns: [
                             TestColumn.new('id', :uuid),
                             TestColumn.new('account_id', :uuid),
                             TestColumn.new('title', :string),
                             TestColumn.new('created_at', :datetime),
                             TestColumn.new('updated_at', :datetime)
                           ])

          File.write('app/models/models/article.rb', "class Models::Article < ApplicationRecord; end\n")
          File.write('db/structures/articles_structure.yaml', <<~YAML)
            model: Models::Article
            resource_name: articles
            actor: user
            resource_owner_id: account_id
            resource_owner: account
            uploaders: []
            search_able: []
            domains:
              action_list:
                use_case:
                  contract:
                    - "required(:account_id).filled(:string)"
                    - "optional(:title).maybe(:string)"
              action_fetch_by_id:
                use_case:
                  contract: []
              action_create:
                use_case:
                  contract: []
              action_update:
                use_case:
                  contract: []
              action_destroy:
                use_case:
                  contract: []
            entity:
              db_attributes: [id, created_at, updated_at]
          YAML

          instance = klass.new(['articles'])
          instance.send(:setup_variables)

          # Test field_exists_in_contract? directly
          expect(instance.send(:field_exists_in_contract?, 'account_id', 'list')).to be true
          expect(instance.send(:field_exists_in_contract?, 'account_id', 'fetch_by_id')).to be false
          expect(instance.send(:field_exists_in_contract?, 'title', 'list')).to be true
          expect(instance.send(:field_exists_in_contract?, 'nonexistent', 'list')).to be false
        end
      end
    end

    it 'returns true when field exists in contract as optional' do
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

          setup_test_model(class_name: 'Article', columns: [
                             TestColumn.new('id', :uuid),
                             TestColumn.new('account_id', :uuid),
                             TestColumn.new('created_at', :datetime),
                             TestColumn.new('updated_at', :datetime)
                           ])

          File.write('app/models/models/article.rb', "class Models::Article < ApplicationRecord; end\n")
          File.write('db/structures/articles_structure.yaml', <<~YAML)
            model: Models::Article
            resource_name: articles
            actor: user
            resource_owner_id: account_id
            resource_owner: account
            uploaders: []
            search_able: []
            domains:
              action_list:
                use_case:
                  contract:
                    - "optional(:account_id).maybe(:string)"
              action_fetch_by_id:
                use_case:
                  contract: []
              action_create:
                use_case:
                  contract: []
              action_update:
                use_case:
                  contract: []
              action_destroy:
                use_case:
                  contract: []
            entity:
              db_attributes: [id, created_at, updated_at]
          YAML

          instance = klass.new(['articles'])
          instance.send(:setup_variables)

          expect(instance.send(:field_exists_in_contract?, 'account_id', 'list')).to be true
        end
      end
    end

    it 'returns false when field_name is blank' do
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

          setup_test_model(class_name: 'Article', columns: [
                             TestColumn.new('id', :uuid),
                             TestColumn.new('created_at', :datetime),
                             TestColumn.new('updated_at', :datetime)
                           ])

          File.write('app/models/models/article.rb', "class Models::Article < ApplicationRecord; end\n")
          File.write('db/structures/articles_structure.yaml', <<~YAML)
            model: Models::Article
            resource_name: articles
            actor: user
            resource_owner_id:
            resource_owner: account
            uploaders: []
            search_able: []
            domains:
              action_list:
                use_case:
                  contract: []
              action_fetch_by_id:
                use_case:
                  contract: []
              action_create:
                use_case:
                  contract: []
              action_update:
                use_case:
                  contract: []
              action_destroy:
                use_case:
                  contract: []
            entity:
              db_attributes: [id, created_at, updated_at]
          YAML

          instance = klass.new(['articles'])
          instance.send(:setup_variables)

          expect(instance.send(:field_exists_in_contract?, nil, 'list')).to be false
          expect(instance.send(:field_exists_in_contract?, '', 'list')).to be false
        end
      end
    end
  end

  describe 'conditional resource_owner_id filtering' do
    it 'does NOT use resource_owner_id filter when field is NOT in contract' do
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

          setup_test_model(class_name: 'Article', columns: [
                             TestColumn.new('id', :uuid),
                             TestColumn.new('account_id', :uuid),
                             TestColumn.new('title', :string),
                             TestColumn.new('created_at', :datetime),
                             TestColumn.new('updated_at', :datetime)
                           ])

          File.write('app/models/models/article.rb', "class Models::Article < ApplicationRecord; end\n")
          File.write('db/structures/articles_structure.yaml', <<~YAML)
            model: Models::Article
            resource_name: articles
            actor: user
            resource_owner_id: account_id
            resource_owner: account
            uploaders: []
            search_able: []
            domains:
              action_list:
                use_case:
                  contract:
                    - "optional(:title).maybe(:string)"
                    # account_id TIDAK ADA di contract
              action_fetch_by_id:
                use_case:
                  contract: []
              action_create:
                use_case:
                  contract: []
              action_update:
                use_case:
                  contract: []
              action_destroy:
                use_case:
                  contract: []
            entity:
              db_attributes: [id, created_at, updated_at]
          YAML

          klass.new(['articles']).generate_use_case

          # Check list repository - should NOT have resource_owner_id filter
          list_repo = File.read(RiderKick.configuration.domains_path + '/repositories/articles/list_article.rb')
          expect(list_repo).not_to match(/\.where\(account_id:/)
          expect(list_repo).to match(/resources = Models::Article\s*$/)

          # Check fetch_by_id repository - should NOT have resource_owner_id filter
          fetch_repo = File.read(RiderKick.configuration.domains_path + '/repositories/articles/fetch_article_by_id.rb')
          expect(fetch_repo).not_to match(/find_by\(id: @id, account_id:/)
          expect(fetch_repo).to match(/find_by\(id: @id\)/)

          # Check update repository - should NOT have resource_owner_id filter
          update_repo = File.read(RiderKick.configuration.domains_path + '/repositories/articles/update_article.rb')
          expect(update_repo).not_to match(/find_by\(id: @id, account_id:/)
          expect(update_repo).to match(/find_by\(id: @id\)/)

          # Check destroy repository - should NOT have resource_owner_id filter
          destroy_repo = File.read(RiderKick.configuration.domains_path + '/repositories/articles/destroy_article.rb')
          expect(destroy_repo).not_to match(/find_by\(id: @id, account_id:/)
          expect(destroy_repo).to match(/find_by\(id: @id\)/)
        end
      end
    end

    it 'DOES use resource_owner_id filter when field IS in contract' do
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

          setup_test_model(class_name: 'Article', columns: [
                             TestColumn.new('id', :uuid),
                             TestColumn.new('account_id', :uuid),
                             TestColumn.new('title', :string),
                             TestColumn.new('created_at', :datetime),
                             TestColumn.new('updated_at', :datetime)
                           ])

          File.write('app/models/models/article.rb', "class Models::Article < ApplicationRecord; end\n")
          File.write('db/structures/articles_structure.yaml', <<~YAML)
            model: Models::Article
            resource_name: articles
            actor: user
            resource_owner_id: account_id
            resource_owner: account
            uploaders: []
            search_able: []
            domains:
              action_list:
                use_case:
                  contract:
                    - "required(:account_id).filled(:string)"
                    - "optional(:title).maybe(:string)"
              action_fetch_by_id:
                use_case:
                  contract:
                    - "required(:account_id).filled(:string)"
              action_update:
                use_case:
                  contract:
                    - "required(:account_id).filled(:string)"
              action_destroy:
                use_case:
                  contract:
                    - "required(:account_id).filled(:string)"
              action_create:
                use_case:
                  contract: []
            entity:
              db_attributes: [id, created_at, updated_at]
          YAML

          klass.new(['articles']).generate_use_case

          # Check list repository - SHOULD have resource_owner_id filter
          list_repo = File.read(RiderKick.configuration.domains_path + '/repositories/articles/list_article.rb')
          expect(list_repo).to match(/\.where\(account_id: @params\.account_id\)/)

          # Check fetch_by_id repository - SHOULD have resource_owner_id filter
          fetch_repo = File.read(RiderKick.configuration.domains_path + '/repositories/articles/fetch_article_by_id.rb')
          expect(fetch_repo).to match(/find_by\(id: @id, account_id: @params\.account_id\)/)

          # Check update repository - SHOULD have resource_owner_id filter
          update_repo = File.read(RiderKick.configuration.domains_path + '/repositories/articles/update_article.rb')
          expect(update_repo).to match(/find_by\(id: @id, account_id: @params\.account_id\)/)

          # Check destroy repository - SHOULD have resource_owner_id filter
          destroy_repo = File.read(RiderKick.configuration.domains_path + '/repositories/articles/destroy_article.rb')
          expect(destroy_repo).to match(/find_by\(id: @id, account_id: @params\.account_id\)/)
        end
      end
    end

    it 'uses resource_owner_id filter only for actions where it exists in contract' do
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

          setup_test_model(class_name: 'Article', columns: [
                             TestColumn.new('id', :uuid),
                             TestColumn.new('account_id', :uuid),
                             TestColumn.new('title', :string),
                             TestColumn.new('created_at', :datetime),
                             TestColumn.new('updated_at', :datetime)
                           ])

          File.write('app/models/models/article.rb', "class Models::Article < ApplicationRecord; end\n")
          File.write('db/structures/articles_structure.yaml', <<~YAML)
            model: Models::Article
            resource_name: articles
            actor: user
            resource_owner_id: account_id
            resource_owner: account
            uploaders: []
            search_able: []
            domains:
              action_list:
                use_case:
                  contract:
                    - "required(:account_id).filled(:string)"
              action_fetch_by_id:
                use_case:
                  contract: []
                    # account_id TIDAK ADA di contract untuk fetch_by_id
              action_create:
                use_case:
                  contract: []
              action_update:
                use_case:
                  contract:
                    - "required(:account_id).filled(:string)"
              action_destroy:
                use_case:
                  contract: []
            entity:
              db_attributes: [id, created_at, updated_at]
          YAML

          klass.new(['articles']).generate_use_case

          # List should have filter
          list_repo = File.read(RiderKick.configuration.domains_path + '/repositories/articles/list_article.rb')
          expect(list_repo).to match(/\.where\(account_id: @params\.account_id\)/)

          # Fetch_by_id should NOT have filter
          fetch_repo = File.read(RiderKick.configuration.domains_path + '/repositories/articles/fetch_article_by_id.rb')
          expect(fetch_repo).not_to match(/find_by\(id: @id, account_id:/)
          expect(fetch_repo).to match(/find_by\(id: @id\)/)

          # Update should have filter
          update_repo = File.read(RiderKick.configuration.domains_path + '/repositories/articles/update_article.rb')
          expect(update_repo).to match(/find_by\(id: @id, account_id: @params\.account_id\)/)

          # Destroy should NOT have filter
          destroy_repo = File.read(RiderKick.configuration.domains_path + '/repositories/articles/destroy_article.rb')
          expect(destroy_repo).not_to match(/find_by\(id: @id, account_id:/)
          expect(destroy_repo).to match(/find_by\(id: @id\)/)
        end
      end
    end
  end

  describe 'instance variables setup' do
    it 'sets @actor_id correctly from structure.actor_id' do
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

          setup_test_model(class_name: 'Article', columns: [
                             TestColumn.new('id', :uuid),
                             TestColumn.new('created_at', :datetime),
                             TestColumn.new('updated_at', :datetime)
                           ])

          File.write('app/models/models/article.rb', "class Models::Article < ApplicationRecord; end\n")
          File.write('db/structures/articles_structure.yaml', <<~YAML)
            model: Models::Article
            resource_name: articles
            actor: user
            actor_id: custom_user_id
            resource_owner_id: account_id
            resource_owner: account
            uploaders: []
            search_able: []
            domains:
              action_list:
                use_case:
                  contract: []
              action_fetch_by_id:
                use_case:
                  contract: []
              action_create:
                use_case:
                  contract: []
              action_update:
                use_case:
                  contract: []
              action_destroy:
                use_case:
                  contract: []
            entity:
              db_attributes: [id, created_at, updated_at]
          YAML

          instance = klass.new(['articles'])
          instance.send(:setup_variables)

          expect(instance.instance_variable_get(:@actor_id)).to eq('custom_user_id')
        end
      end
    end

    it 'generates @actor_id from @actor when actor_id not present in structure' do
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

          setup_test_model(class_name: 'Article', columns: [
                             TestColumn.new('id', :uuid),
                             TestColumn.new('created_at', :datetime),
                             TestColumn.new('updated_at', :datetime)
                           ])

          File.write('app/models/models/article.rb', "class Models::Article < ApplicationRecord; end\n")
          File.write('db/structures/articles_structure.yaml', <<~YAML)
            model: Models::Article
            resource_name: articles
            actor: admin
            resource_owner_id: account_id
            resource_owner: account
            uploaders: []
            search_able: []
            domains:
              action_list:
                use_case:
                  contract: []
              action_fetch_by_id:
                use_case:
                  contract: []
              action_create:
                use_case:
                  contract: []
              action_update:
                use_case:
                  contract: []
              action_destroy:
                use_case:
                  contract: []
            entity:
              db_attributes: [id, created_at, updated_at]
          YAML

          instance = klass.new(['articles'])
          instance.send(:setup_variables)

          expect(instance.instance_variable_get(:@actor_id)).to eq('admin_id')
        end
      end
    end

    it 'sets @has_resource_owner_id_in_*_contract flags correctly' do
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

          setup_test_model(class_name: 'Article', columns: [
                             TestColumn.new('id', :uuid),
                             TestColumn.new('account_id', :uuid),
                             TestColumn.new('created_at', :datetime),
                             TestColumn.new('updated_at', :datetime)
                           ])

          File.write('app/models/models/article.rb', "class Models::Article < ApplicationRecord; end\n")
          File.write('db/structures/articles_structure.yaml', <<~YAML)
            model: Models::Article
            resource_name: articles
            actor: user
            resource_owner_id: account_id
            resource_owner: account
            uploaders: []
            search_able: []
            domains:
              action_list:
                use_case:
                  contract:
                    - "required(:account_id).filled(:string)"
              action_fetch_by_id:
                use_case:
                  contract: []
              action_create:
                use_case:
                  contract:
                    - "required(:account_id).filled(:string)"
              action_update:
                use_case:
                  contract: []
              action_destroy:
                use_case:
                  contract:
                    - "required(:account_id).filled(:string)"
            entity:
              db_attributes: [id, created_at, updated_at]
          YAML

          instance = klass.new(['articles'])
          instance.send(:setup_variables)

          expect(instance.instance_variable_get(:@has_resource_owner_id_in_list_contract)).to be true
          expect(instance.instance_variable_get(:@has_resource_owner_id_in_fetch_by_id_contract)).to be false
          expect(instance.instance_variable_get(:@has_resource_owner_id_in_create_contract)).to be true
          expect(instance.instance_variable_get(:@has_resource_owner_id_in_update_contract)).to be false
          expect(instance.instance_variable_get(:@has_resource_owner_id_in_destroy_contract)).to be true
        end
      end
    end
  end

  describe 'helper methods' do
    it 'has_resource_owner_id_in_contract? returns correct values' do
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

          setup_test_model(class_name: 'Article', columns: [
                             TestColumn.new('id', :uuid),
                             TestColumn.new('account_id', :uuid),
                             TestColumn.new('created_at', :datetime),
                             TestColumn.new('updated_at', :datetime)
                           ])

          File.write('app/models/models/article.rb', "class Models::Article < ApplicationRecord; end\n")
          File.write('db/structures/articles_structure.yaml', <<~YAML)
            model: Models::Article
            resource_name: articles
            actor: user
            resource_owner_id: account_id
            resource_owner: account
            uploaders: []
            search_able: []
            domains:
              action_list:
                use_case:
                  contract:
                    - "required(:account_id).filled(:string)"
              action_fetch_by_id:
                use_case:
                  contract: []
              action_create:
                use_case:
                  contract: []
              action_update:
                use_case:
                  contract: []
              action_destroy:
                use_case:
                  contract: []
            entity:
              db_attributes: [id, created_at, updated_at]
          YAML

          instance = klass.new(['articles'])
          instance.send(:setup_variables)

          expect(instance.send(:has_resource_owner_id_in_contract?, 'list')).to be true
          expect(instance.send(:has_resource_owner_id_in_contract?, 'fetch_by_id')).to be false
          expect(instance.send(:has_resource_owner_id_in_contract?, 'fetch')).to be false
          expect(instance.send(:has_resource_owner_id_in_contract?, 'create')).to be false
          expect(instance.send(:has_resource_owner_id_in_contract?, 'update')).to be false
          expect(instance.send(:has_resource_owner_id_in_contract?, 'destroy')).to be false
          expect(instance.send(:has_resource_owner_id_in_contract?, 'unknown')).to be false
        end
      end
    end
  end

  describe 'use case list contract generation' do
    it 'includes resource_owner_id in contract when it exists in contract list' do
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

          setup_test_model(class_name: 'Article', columns: [
                             TestColumn.new('id', :uuid),
                             TestColumn.new('account_id', :uuid),
                             TestColumn.new('created_at', :datetime),
                             TestColumn.new('updated_at', :datetime)
                           ])

          File.write('app/models/models/article.rb', "class Models::Article < ApplicationRecord; end\n")
          File.write('db/structures/articles_structure.yaml', <<~YAML)
            model: Models::Article
            resource_name: articles
            actor: user
            resource_owner_id: account_id
            resource_owner: account
            uploaders: []
            search_able: []
            domains:
              action_list:
                use_case:
                  contract:
                    - "required(:account_id).filled(:string)"
              action_fetch_by_id:
                use_case:
                  contract: []
              action_create:
                use_case:
                  contract: []
              action_update:
                use_case:
                  contract: []
              action_destroy:
                use_case:
                  contract: []
            entity:
              db_attributes: [id, created_at, updated_at]
          YAML

          klass.new(['articles']).generate_use_case

          list_usecase = File.read(RiderKick.configuration.domains_path + '/use_cases/articles/user_list_article.rb')
          # Should include the contract line from YAML
          expect(list_usecase).to include('required(:account_id).filled(:string)')
          # Should NOT add duplicate resource_owner_id since it's already in contract
          # (The template should check @has_resource_owner_id_in_list_contract)
        end
      end
    end

    it 'does NOT include resource_owner_id in contract when it does NOT exist in contract list' do
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

          setup_test_model(class_name: 'Article', columns: [
                             TestColumn.new('id', :uuid),
                             TestColumn.new('account_id', :uuid),
                             TestColumn.new('title', :string),
                             TestColumn.new('created_at', :datetime),
                             TestColumn.new('updated_at', :datetime)
                           ])

          File.write('app/models/models/article.rb', "class Models::Article < ApplicationRecord; end\n")
          File.write('db/structures/articles_structure.yaml', <<~YAML)
            model: Models::Article
            resource_name: articles
            actor: user
            resource_owner_id: account_id
            resource_owner: account
            uploaders: []
            search_able: []
            domains:
              action_list:
                use_case:
                  contract:
                    - "optional(:title).maybe(:string)"
                    # account_id TIDAK ADA di contract
              action_fetch_by_id:
                use_case:
                  contract: []
              action_create:
                use_case:
                  contract: []
              action_update:
                use_case:
                  contract: []
              action_destroy:
                use_case:
                  contract: []
            entity:
              db_attributes: [id, created_at, updated_at]
          YAML

          klass.new(['articles']).generate_use_case

          list_usecase = File.read(RiderKick.configuration.domains_path + '/use_cases/articles/user_list_article.rb')
          # Should NOT include resource_owner_id since it's not in contract
          expect(list_usecase).not_to match(/required\(:account_id\)\.filled\(:string\)/)
        end
      end
    end
  end
end
