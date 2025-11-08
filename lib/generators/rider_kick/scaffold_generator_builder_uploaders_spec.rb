# frozen_string_literal: true

require 'rails/generators'
require 'tmpdir'
require 'active_support/inflector'
require 'fileutils'
require 'generators/rider_kick/scaffold_generator'

RSpec.describe 'rider_kick:scaffold builder (uploaders)' do
  let(:klass) { RiderKick::ScaffoldGenerator }

  it 'menulis mapping uploader: single (has_one) & multiple (has_many) ke builder' do
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

        builder = File.read(RiderKick.configuration.domains_path + '/core/builders/user.rb')
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

  it 'tidak menambahkan duplikasi has_one_attached atau has_many_attached jika sudah ada' do
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

        # Model dengan attachment yang sudah ada
        File.write('app/models/models/user.rb', <<~RUBY)
          class Models::User < ApplicationRecord
            has_one_attached :avatar, dependent: :purge
            has_many_attached :images, dependent: :purge
          end
        RUBY

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

        model_content = File.read('app/models/models/user.rb')

        # Pastikan tidak ada duplikasi
        avatar_count = model_content.scan(/has_one_attached\s+:avatar\b/).count
        images_count = model_content.scan(/has_many_attached\s+:images\b/).count

        expect(avatar_count).to eq(1), "Expected has_one_attached :avatar to appear only once, but found #{avatar_count} times"
        expect(images_count).to eq(1), "Expected has_many_attached :images to appear only once, but found #{images_count} times"
      end
    end
  end

  it 'tetap mendeteksi attachment yang sudah ada dengan format berbeda' do
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

        # Model dengan attachment yang sudah ada dengan format berbeda (tanpa dependent)
        File.write('app/models/models/user.rb', <<~RUBY)
          class Models::User < ApplicationRecord
            has_one_attached :avatar
            has_many_attached :images
          end
        RUBY

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

        model_content = File.read('app/models/models/user.rb')

        # Pastikan tidak ada duplikasi meskipun format berbeda
        avatar_count = model_content.scan(/has_one_attached\s+:avatar\b/).count
        images_count = model_content.scan(/has_many_attached\s+:images\b/).count

        expect(avatar_count).to eq(1), "Expected has_one_attached :avatar to appear only once, but found #{avatar_count} times"
        expect(images_count).to eq(1), "Expected has_many_attached :images to appear only once, but found #{images_count} times"
      end
    end
  end
end
