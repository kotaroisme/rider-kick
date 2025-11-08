# frozen_string_literal: true

require 'rails/generators'
require 'tmpdir'
require 'active_support/inflector'

require 'fileutils'
require 'generators/rider_kick/scaffold_generator'

RSpec.describe 'rider_kick:scaffold generator (success)' do
  let(:klass) { RiderKick::ScaffoldGenerator }

  it 'menghasilkan use_cases, repositories, builder, dan entity dari YAML struktur' do
    Dir.mktmpdir do |dir|
      Dir.chdir(dir) do
        # 1) siapkan kerangka clean-arch minimal
        FileUtils.mkdir_p(RiderKick.configuration.domains_path + '/core/use_cases')
        FileUtils.mkdir_p(RiderKick.configuration.domains_path + '/core/repositories')
        FileUtils.mkdir_p(RiderKick.configuration.domains_path + '/core/builders')
        FileUtils.mkdir_p(RiderKick.configuration.domains_path + '/core/entities')
        FileUtils.mkdir_p('app/models/models')
        FileUtils.mkdir_p('db/structures')

        # 2) stub namespace & model + metadata kolom
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

        # 3) file model untuk inject (hanya dipakai jika uploaders ada)
        File.write('app/models/models/user.rb', <<~RUBY)
          class Models::User < ApplicationRecord
          end
        RUBY

        # 4) YAML struktur minimal (hasil dari generator :structure pada umumnya)
        File.write('db/structures/users_structure.yaml', <<~YAML)
          model: Models::User
          resource_name: users
          actor: owner
          resource_owner_id:
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
            db_attributes:
              - id
              - created_at
              - updated_at
        YAML

        # 5) jalankan generator
        instance = klass.new(['users'])  # arg_structure = "users"
        instance.generate_use_case

        # 6) verifikasi artefak
        # use_cases (tanpa route scope): app/domains/core/use_cases/users/<use_case>.rb
        ['owner_create_user', 'owner_update_user', 'owner_list_user', 'owner_destroy_user', 'owner_fetch_user_by_id'].each do |uc|
          expect(File).to exist(File.join(RiderKick.configuration.domains_path + '/core/use_cases/users', "#{uc}.rb"))
        end
        # repositories: app/domains/core/repositories/users/<repo>.rb
        ['create_user', 'update_user', 'list_user', 'destroy_user', 'fetch_user_by_id'].each do |repo|
          expect(File).to exist(File.join(RiderKick.configuration.domains_path + '/core/repositories/users', "#{repo}.rb"))
        end
        # builder & entity
        expect(File).to exist(RiderKick.configuration.domains_path + '/core/builders/user.rb')
        expect(File).to exist(RiderKick.configuration.domains_path + '/core/entities/user.rb')
      end
    end
  end
end
