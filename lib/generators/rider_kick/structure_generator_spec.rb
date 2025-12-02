# frozen_string_literal: true

require 'rails/generators'
require 'tmpdir'
require 'generators/rider_kick/structure_generator'

RSpec.describe 'rider_kick:structure generator' do
  let(:klass) { RiderKick::Structure }

  it 'mengangkat ValidationError jika app/domains belum ada' do
    Dir.mktmpdir do |dir|
      Dir.chdir(dir) do
        expect(Dir.exist?(RiderKick.configuration.domains_path)).to be false
        instance = klass.new(['Models::User'])           # ← instansiasi dengan argumen
        expect { instance.generate_use_case }            # ← panggil task langsung
          .to raise_error(RiderKick::ValidationError, /clean_arch.*--setup/i)
      end
    end
  end
end
