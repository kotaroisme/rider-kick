# frozen_string_literal: true

require 'rails/generators'
require 'tmpdir'
require 'active_support/inflector'

require 'fileutils'
require 'generators/rider_kick/scaffold_generator'

RSpec.describe 'rider_kick:scaffold contracts' do
  let(:klass) { RiderKick::ScaffoldGenerator }

  it 'menulis kontrak schema yang tepat di use_cases (list/fetch_by_id/create/update/destroy)' do
    Dir.mktmpdir do |dir|
      Dir.chdir(dir) do
        # Set domain scope to core for this test
        RiderKick.configuration.domain_scope = 'core/'

        FileUtils.mkdir_p([
                            RiderKick.configuration.domains_path + '/core/use_cases',
                            RiderKick.configuration.domains_path + '/core/repositories',
                            RiderKick.configuration.domains_path + '/core/builders',
                            RiderKick.configuration.domains_path + '/core/entities',
                            'app/models/models',
                            'db/structures'
                          ])

        # Stub model & kolom
        Object.send(:remove_const, :Models) if Object.const_defined?(:Models)
        Object.send(:remove_const, :Column) if Object.const_defined?(:Column)
        module Models; end

        Column = Struct.new(:name, :type, :sql_type, :null, :default, :precision, :scale, :limit)
        class Models::User
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

        File.write('app/models/models/user.rb', "class Models::User < ApplicationRecord; end\n")

        # YAML struktur minimal
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

        # Generate
        klass.new(['users']).generate_use_case

        # Cek isi kontrak
        readf = ->(path) { File.read(File.join(path)) }
        base  = RiderKick.configuration.domains_path + '/use_cases/users'

        expect(readf["#{base}/owner_list_user.rb"])
          .to include('Core::UseCases::Contract::Default', 'Contract::Pagination')

        expect(readf["#{base}/owner_fetch_user_by_id.rb"])
          .to include('required(:id).filled(:string)')

        expect(readf["#{base}/owner_create_user.rb"])
          .to include('Core::Repositories::Users::CreateUser')

        expect(readf["#{base}/owner_update_user.rb"])
          .to include('required(:id).filled(:string)')

        expect(readf["#{base}/owner_destroy_user.rb"])
          .to include('required(:id).filled(:string)')
      end
    end
  end
end
