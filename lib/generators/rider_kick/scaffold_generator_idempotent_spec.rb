# lib/generators/rider_kick/scaffold_generator_idempotent_spec.rb
# frozen_string_literal: true

require 'rails/generators'
require 'tmpdir'
require 'fileutils'

require 'generators/rider_kick/scaffold_generator'

RSpec.describe 'rider_kick:scaffold generator (idempotent)' do
  let(:klass) { RiderKick::ScaffoldGenerator }

  it 'tidak menduplikasi konten ketika dijalankan ulang' do
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

        # model fisik & YAML minimal
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
          entity: { db_attributes: [id, created_at, updated_at] }
        YAML

        # run pertama
        klass.new(['users']).generate_use_case
        builder_v1 = File.read(RiderKick.configuration.domains_path + '/core/builders/user.rb')

        # run kedua (seharusnya idempotent)
        klass.new(['users']).generate_use_case
        builder_v2 = File.read(RiderKick.configuration.domains_path + '/core/builders/user.rb')

        # konten tidak berubah
        expect(builder_v2).to eq(builder_v1)

        # entity & repositori tetap 1 file masing-masing
        expect(Dir[RiderKick.configuration.domains_path + '/core/entities/user.rb'].size).to eq(1)
        expect(Dir[RiderKick.configuration.domains_path + '/core/repositories/users/*.rb'].size).to be >= 5
      end
    end
  end
end
