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
          uploaders: [{ name: 'avatar', type: 'single' }, { name: 'images', type: 'multiple' }]
          search_able: []
          domains:
            action_list:        { use_case: { contract: [] } }
            action_fetch_by_id: { use_case: { contract: [] } }
            action_create:      { use_case: { contract: [] } }
            action_update:      { use_case: { contract: [] } }
            action_destroy:     { use_case: { contract: [] } }
          entity: { db_attributes: [id, created_at, updated_at] }
        YAML

        klass.new(['users']).generate_use_case

        builder = File.read('app/domains/core/builders/user.rb')
        # singular -> satu URL string
        expect(builder).to include('def with_avatar_url(model)')
        expect(builder).to include('model.avatar.url')
        # plural -> array dengan helper build_assets
        expect(builder).to include('def with_images_urls(model)')
        expect(builder).to include('model.images.map')
        expect(builder).to include('attachment.url')
      end
    end
  end
end
