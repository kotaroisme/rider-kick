# frozen_string_literal: true

require 'rails/generators'
require 'tmpdir'
require 'active_support/inflector'
require 'ostruct'
require 'fileutils'
require 'generators/rider_kick/scaffold_generator'

RSpec.describe 'rider_kick:scaffold builder (uploaders)' do
  let(:klass) { RiderKick::ScaffoldGenerator }

  it 'menulis mapping uploader: single (has_one) & multiple (has_many) ke builder' do
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

        # avatar (singular) + images (plural)
        File.write('db/structures/users_structure.yaml', <<~YAML)
          model: Models::User
          resource_name: users
          actor: owner
          uploaders: [avatar, images]
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

        builder = File.read('app/domains/core/builders/user.rb')
        # singular -> satu URL string
        expect(builder).to include('avatar: (Rails.application.routes.url_helpers.polymorphic_url(params.avatar)')
        # plural -> array dengan helper build_assets
        expect(builder).to include('images: build_assets(params.images)')
        expect(builder).to include('def build_assets(assets)')
      end
    end
  end
end
