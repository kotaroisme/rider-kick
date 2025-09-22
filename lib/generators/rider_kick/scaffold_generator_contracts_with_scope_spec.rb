# frozen_string_literal: true

require 'rails/generators'
require 'tmpdir'
require 'active_support/inflector'
require 'ostruct'
require 'fileutils'
require 'generators/rider_kick/scaffold_generator'

RSpec.describe 'rider_kick:scaffold contracts (with scope)' do
  let(:klass) { RiderKick::ScaffoldGenerator }

  it 'menaruh use_cases di folder scope yang benar & menulis kontrak sesuai' do
    Dir.mktmpdir do |dir|
      Dir.chdir(dir) do
        FileUtils.mkdir_p(%w[
                            app/domains/core/use_cases
                            app/domains/core/repositories
                            app/domains/core/builders
                            app/domains/core/entities
                            app/models/models
                            db/structures
                          ])

        File.write('app/models/models/user.rb', "class Models::User < ApplicationRecord; end\n")

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
          entity: { skipped_fields: [id, created_at, updated_at] }
        YAML

        klass.new(['users', 'scope:dashboard']).generate_use_case

        base = 'app/domains/core/use_cases/dashboard/users'
        %w[owner_list_user owner_fetch_user_by_id owner_create_user owner_update_user owner_destroy_user].each do |uc|
          expect(File).to exist("#{base}/#{uc}.rb")
        end

        expect(File.read("#{base}/owner_list_user.rb"))
          .to include('Core::UseCases::Dashboard::Users::OwnerListUser')
      end
    end
  end
end
