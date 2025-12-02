# frozen_string_literal: true

require 'rails/generators'
require 'tmpdir'
require 'fileutils'
require 'generators/rider_kick/clean_arch_generator'

RSpec.describe 'rider_kick:clean_arch generator (FactoryBot & Faker setup)' do
  let(:klass) { RiderKick::CleanArchGenerator }

  it 'sets up FactoryBot and Faker with proper directory structure and configuration' do
    Dir.mktmpdir do |dir|
      Dir.chdir(dir) do
        # Setup minimal Rails structure
        FileUtils.mkdir_p('config')
        FileUtils.mkdir_p('spec')
        File.write('Gemfile', "source 'https://rubygems.org'\n")

        instance = klass.new([])
        opts = double('options', setup: true)
        allow(opts).to receive(:[]).and_return(nil)
        allow(opts).to receive(:[]).with(:setup).and_return(true)
        allow(opts).to receive(:[]).with(:engine).and_return(nil)
        allow(opts).to receive(:[]).with(:quiet).and_return(false)
        allow(instance).to receive(:options).and_return(opts)

        # Skip other setup methods
        allow(instance).to receive(:copy_domain_file)
        allow(instance).to receive(:setup_initializers)
        allow(instance).to receive(:setup_dotenv)
        allow(instance).to receive(:setup_gitignore)
        allow(instance).to receive(:setup_rubocop)
        allow(instance).to receive(:setup_init_migration)
        allow(instance).to receive(:setup_models)
        allow(instance).to receive(:setup_active_storage)
        allow(instance).to receive(:setup_readme)
        allow(instance).to receive(:run)

        # Call setup methods
        instance.send(:setup_domain_structure)
        instance.send(:setup_rspec)

        # Verify FactoryBot directory structure
        expect(Dir.exist?('spec/factories')).to be true

        # Verify FactoryBot support file
        factory_bot_support = 'spec/support/factory_bot.rb'
        expect(File.exist?(factory_bot_support)).to be true

        factory_bot_content = File.read(factory_bot_support)
        expect(factory_bot_content).to include('FactoryBot::Syntax::Methods')
        expect(factory_bot_content).to include('config.include FactoryBot::Syntax::Methods')
        expect(factory_bot_content).to include('sequence :email')
        expect(factory_bot_content).to include('sequence :uuid')

        # Verify Faker support file
        faker_support = 'spec/support/faker.rb'
        expect(File.exist?(faker_support)).to be true

        faker_content = File.read(faker_support)
        expect(faker_content).to include('Faker::Config')
        expect(faker_content).to include('module FakerHelpers')
        expect(faker_content).to include('def self.random_phone')
        expect(faker_content).to include('def self.random_address')
        expect(faker_content).to include('def self.random_url')
        expect(faker_content).to include('config.include FakerHelpers')

        # Verify .gitkeep file
        gitkeep = 'spec/factories/.gitkeep'
        expect(File.exist?(gitkeep)).to be true

        gitkeep_content = File.read(gitkeep)
        expect(gitkeep_content).to include('FactoryBot.define')
        expect(gitkeep_content).to include('Example:')

        # Verify rails_helper includes
        rails_helper = 'spec/rails_helper.rb'
        expect(File.exist?(rails_helper)).to be true

        rails_helper_content = File.read(rails_helper)
        expect(rails_helper_content).to include("Dir[Rails.root.join('spec', 'support', '**', '*.rb')].sort.each { |f| require f }")
        expect(rails_helper_content).to include('config.include FactoryBot::Syntax::Methods')
        expect(rails_helper_content).to include('config.include FakerHelpers')
      end
    end
  end

  it 'generates Gemfile with correct dependencies' do
    Dir.mktmpdir do |dir|
      Dir.chdir(dir) do
        FileUtils.mkdir_p('config')
        File.write('Gemfile', <<~GEMFILE)
          source 'https://rubygems.org'

          group :development, :test do
          end
        GEMFILE

        instance = klass.new([])
        opts = double('options', setup: true)
        allow(opts).to receive(:[]).and_return(nil)
        allow(opts).to receive(:[]).with(:setup).and_return(true)
        allow(opts).to receive(:[]).with(:engine).and_return(nil)
        allow(opts).to receive(:[]).with(:quiet).and_return(false)
        allow(instance).to receive(:options).and_return(opts)

        # Skip validation and other setup methods
        allow(instance).to receive(:validate_setup_option)
        allow(instance).to receive(:setup_configuration)
        allow(instance).to receive(:run)

        # Only run create_gem_dependencies
        instance.create_gem_dependencies

        gemfile_content = File.read('Gemfile')

        # Verify gems are added in correct group
        expect(gemfile_content).to include('group :development, :test do')
        expect(gemfile_content).to include('gem "rspec-rails"')
        expect(gemfile_content).to include('gem "factory_bot_rails"')
        expect(gemfile_content).to include('gem "faker"')
        expect(gemfile_content).to include('gem "shoulda-matchers"')

        # Verify other gems
        expect(gemfile_content).to include("gem 'dotenv-rails'")
        expect(gemfile_content).to include("gem 'hashie'")
        expect(gemfile_content).to include("gem 'pagy'")
      end
    end
  end
end
