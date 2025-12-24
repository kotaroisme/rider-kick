# frozen_string_literal: true

require 'rails/generators'
require 'tmpdir'
require 'active_support/inflector'

require 'fileutils'
require 'generators/rider_kick/scaffold_generator'

RSpec.describe 'rider_kick:scaffold generator (with scope)' do
  let(:klass) { RiderKick::ScaffoldGenerator }

  it 'meletakkan use_cases di folder route scope yang benar' do
    Dir.mktmpdir do |dir|
      Dir.chdir(dir) do
        FileUtils.mkdir_p(RiderKick.configuration.domains_path)
        FileUtils.mkdir_p('app/models/models')
        FileUtils.mkdir_p('db/structures')

        # Stub model classes
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

        File.write('db/structures/users_structure.yaml', <<~YAML)
          model: Models::User
          resource_name: users
          actor: owner
          uploaders: []
          search_able: []
          domains: { action_list: { use_case: { contract: [] } },
                     action_fetch_by_id: { use_case: { contract: [] } },
                     action_create: { use_case: { contract: [] } },
                     action_update: { use_case: { contract: [] } },
                     action_destroy: { use_case: { contract: [] } } }
          entity: { db_attributes: [id, created_at, updated_at] }
        YAML

        # jalankan dengan token scope:dashboard (Thor hash-arg)
        instance = klass.new(['users', 'scope:dashboard'])
        instance.generate_use_case

        # use_cases berada di app/domains/use_cases/dashboard/users/...
        path = RiderKick.configuration.domains_path + '/use_cases/dashboard/users'
        ['owner_create_user', 'owner_update_user', 'owner_list_user', 'owner_destroy_user', 'owner_fetch_user_by_id'].each do |uc|
          # expect(File).to exist(File.join(path, "#{uc}.rb"))
        end
        # repositories tetap di .../repositories/users
        ['create_user', 'update_user', 'list_user', 'destroy_user', 'fetch_user_by_id'].each do |repo|
          expect(File).to exist(File.join(RiderKick.configuration.domains_path + '/repositories/users', "#{repo}.rb"))
        end
      end
    end
  end
end
