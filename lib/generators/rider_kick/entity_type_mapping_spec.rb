# lib/generators/rider_kick/entity_type_mapping_spec.rb
# frozen_string_literal: true

require 'rails/generators'
require 'tmpdir'
require 'fileutils'
require 'generators/rider_kick/scaffold_generator'

RSpec.describe 'entity type mapping' do
  let(:klass) { RiderKick::ScaffoldGenerator }

  it 'memetakan kolom ke Types::Strict yang benar' do
    # Store original configuration
    original_engine = RiderKick.configuration.engine_name
    original_domain = RiderKick.configuration.domain_scope

    Dir.mktmpdir do |dir|
      Dir.chdir(dir) do
        # Reset configuration for this test
        RiderKick.configuration.engine_name = nil
        RiderKick.configuration.domain_scope = 'core/'

        FileUtils.mkdir_p [
          RiderKick.configuration.domains_path,
          'app/models/models',
          'db/structures'
        ]

        # pakai stub shared Models::User dari spec/support (sudah auto-require)
        File.write('app/models/models/user.rb', "class Models::User < ApplicationRecord; end\n")
        File.write('db/structures/users_structure.yaml', <<~YAML)
          model: Models::User
          resource_name: users
          actor: owner
          resource_owner_id: account_id
          resource_owner: account
          uploaders: [{ name: 'avatar', type: 'single' }]
          search_able: []
          domains:
            action_list:        { use_case: { contract: [] } }
            action_fetch_by_id: { use_case: { contract: [] } }
            action_create:      { use_case: { contract: [] } }
            action_update:      { use_case: { contract: [] } }
            action_destroy:     { use_case: { contract: [] } }
            entity: { db_attributes: ['id', 'name', 'price', 'created_at', 'updated_at'] }
        YAML

        klass.new(['users']).generate_use_case

        entity = File.read(RiderKick.configuration.domains_path + '/entities/user.rb')
        # harapannya: string, datetime dipetakan ke Strict
        expect(entity).to match(/Types::Strict::String/)
        expect(entity).to match(/Types::Strict::Time|Types::Strict::Date|Types::Strict::DateTime/)
      end
    ensure
      # Restore original configuration
      RiderKick.configuration.engine_name = original_engine
      RiderKick.configuration.domain_scope = original_domain
    end
  end
end
