# lib/generators/rider_kick/entity_type_mapping_spec.rb
# frozen_string_literal: true

require 'rails/generators'
require 'tmpdir'
require 'fileutils'
require 'ostruct'
require 'generators/rider_kick/scaffold_generator'

RSpec.describe 'entity type mapping' do
  let(:klass) { RiderKick::ScaffoldGenerator }

  it 'memetakan kolom ke Types::Strict yang benar' do
    Dir.mktmpdir do |dir|
      Dir.chdir(dir) do
        FileUtils.mkdir_p %w[
          app/domains/core/use_cases
          app/domains/core/repositories
          app/domains/core/builders
          app/domains/core/entities
          app/models/models
          db/structures
        ]

        # pakai stub shared Models::User dari spec/support (sudah auto-require)
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

        klass.new(['users']).generate_use_case

        entity = File.read('app/domains/core/entities/user.rb')
        # harapannya: string, decimal, datetime dipetakan ke Strict
        expect(entity).to match(/Types::Strict::String/)
        expect(entity).to match(/Types::Strict::Decimal|Types::Coercible::Decimal/)
        expect(entity).to match(/Types::Strict::Time|Types::Strict::Date|Types::Strict::DateTime/)
      end
    end
  end
end
