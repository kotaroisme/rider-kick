# frozen_string_literal: true

require 'rails/generators'
require 'tmpdir'
require 'active_support/inflector'
require 'ostruct'
require 'fileutils'
require 'generators/rider_kick/scaffold_generator'

RSpec.describe 'rider_kick:scaffold contracts' do
  let(:klass) { RiderKick::ScaffoldGenerator }

  it 'menulis kontrak schema yang tepat di use_cases (list/fetch_by_id/create/update/destroy)' do
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

        # Stub model & kolom

        File.write('app/models/models/user.rb', "class Models::User < ApplicationRecord; end\n")

        # YAML struktur minimal
        File.write('db/structures/users_structure.yaml', <<~YAML)
          model: Models::User
          resource_name: users
          actor: owner
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
        base  = RiderKick.configuration.domains_path + '/core/use_cases/users'

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
