# lib/generators/rider_kick/repositories_contract_spec.rb
# frozen_string_literal: true

require 'rails/generators'
require 'tmpdir'
require 'fileutils'
require 'generators/rider_kick/scaffold_generator'

RSpec.describe 'repositories scaffolded content' do
  let(:klass) { RiderKick::ScaffoldGenerator }

  it 'memuat filter resource_owner + pagination + (opsional) search_able' do
    Dir.mktmpdir do |dir|
      Dir.chdir(dir) do
        FileUtils.mkdir_p [
          RiderKick.configuration.domains_path + '/core/use_cases',
          RiderKick.configuration.domains_path + '/core/repositories',
          RiderKick.configuration.domains_path + '/core/builders',
          RiderKick.configuration.domains_path + '/core/entities',
          'app/models/models',
          'db/structures'
        ]
        File.write('app/models/models/user.rb', "class Models::User < ApplicationRecord; end\n")
        File.write('db/structures/users_structure.yaml', <<~YAML)
          model: Models::User
          resource_name: users
          actor: owner
          resource_owner_id: owner_id
          resource_owner: owner
          uploaders: []
          search_able: [name]
          domains:
            action_list:        { use_case: { contract: [] } }
            action_fetch_by_id: { use_case: { contract: [] } }
            action_create:      { use_case: { contract: [] } }
            action_update:      { use_case: { contract: [] } }
            action_destroy:     { use_case: { contract: [] } }
          entity: { db_attributes: [id, created_at, updated_at] }
        YAML

        klass.new(['users']).generate_use_case

        list_repo = File.read(RiderKick.configuration.domains_path + '/repositories/users/list_user.rb')
        expect(list_repo).to match(/resource_owner_id|owner_id|account_id/i) # salah satu pola filter kepemilikan
        expect(list_repo).to match(/paginate|per_page|page/i)                # pagination hook
        expect(list_repo).to match(/name|search/i)                           # search_able minimal

        fetch_repo = File.read(RiderKick.configuration.domains_path + '/repositories/users/fetch_user_by_id.rb')
        expect(fetch_repo).to match(/find_by|where\(.+id:/i)

        create_repo = File.read(RiderKick.configuration.domains_path + '/repositories/users/create_user.rb')
        update_repo = File.read(RiderKick.configuration.domains_path + '/repositories/users/update_user.rb')
        destroy_repo = File.read(RiderKick.configuration.domains_path + '/repositories/users/destroy_user.rb')

        # repos utama terbentuk & memanggil ActiveRecord target
        [create_repo, update_repo, destroy_repo].each do |src|
          expect(src).to include('Models::User')
        end
      end
    end
  end
end
