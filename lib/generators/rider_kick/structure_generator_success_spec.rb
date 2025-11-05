# frozen_string_literal: true

require 'rails/generators'
require 'tmpdir'
require 'active_support/inflector'
require 'generators/rider_kick/structure_generator'
require 'ostruct'

RSpec.describe 'rider_kick:structure generator (success)' do
  let(:klass) { RiderKick::Structure }

  it 'membuat db/structures/<resource>_structure.yaml ketika environment valid' do
    Dir.mktmpdir do |dir|
      Dir.chdir(dir) do
        # 1) siapkan struktur minimal Clean Arch
        FileUtils.mkdir_p(RiderKick.configuration.domains_path + '/core/use_cases')
        FileUtils.mkdir_p('app/models/models')

        # 2) stub namespace & model + metadata kolom

        # 3) jalankan generator
        instance = klass.new(['Models::User', 'actor:owner'])  # ← pakai token
        instance.generate_use_case

        # 4) verifikasi file output
        expect(File).to exist('db/structures/users_structure.yaml')
        yaml = File.read('db/structures/users_structure.yaml')
        expect(yaml).to include('model: Models::User')
        expect(yaml).to include('resource_name: users')
        expect(yaml).to include('actor: owner')
        expect(yaml).to include('- name')          # field dari kolom
        expect(yaml).to include('- price')
      end
    end
  end
end
