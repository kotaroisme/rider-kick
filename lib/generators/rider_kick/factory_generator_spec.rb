# frozen_string_literal: true

require 'rails/generators'
require 'tmpdir'
require 'generators/rider_kick/factory_generator'

RSpec.describe 'rider_kick:factory generator' do
  let(:klass) { RiderKick::FactoryGenerator }

  it 'generates factory with proper format' do
    # Stub the model class
    stub_const('Models', Module.new)
    stub_const('Models::Article', Class.new do
      def self.columns
        [
          Struct.new(:name, :type).new('id', :integer),
          Struct.new(:name, :type).new('title', :string),
          Struct.new(:name, :type).new('content', :text),
          Struct.new(:name, :type).new('user_id', :integer),
          Struct.new(:name, :type).new('published', :boolean),
          Struct.new(:name, :type).new('created_at', :datetime),
          Struct.new(:name, :type).new('updated_at', :datetime)
        ]
      end
    end)

    Dir.mktmpdir do |dir|
      Dir.chdir(dir) do
        FileUtils.mkdir_p('spec/factories/core')

        instance = klass.new(['Models::Article', { 'scope' => 'core' }])
        instance.generate_factory

        factory_file = File.join('spec/factories/core/article.rb')
        expect(File.exist?(factory_file)).to be true

        content = File.read(factory_file)
        expect(content).to include('factory :article')
        expect(content).to include("class: 'Models::Article'")
        expect(content).to include('title')
        expect(content).to include('content')
        expect(content).to include('published')
        expect(content).not_to include('user_id')
        expect(content).not_to include('created_at')
        expect(content).not_to include('updated_at')
      end
    end
  end

  it 'skips all foreign key columns ending with _id' do
    stub_const('Models', Module.new)
    stub_const('Models::Comment', Class.new do
      def self.columns
        [
          Struct.new(:name, :type).new('id', :integer),
          Struct.new(:name, :type).new('body', :text),
          Struct.new(:name, :type).new('user_id', :integer),
          Struct.new(:name, :type).new('post_id', :integer),
          Struct.new(:name, :type).new('author_id', :integer),
          Struct.new(:name, :type).new('created_at', :datetime),
          Struct.new(:name, :type).new('updated_at', :datetime)
        ]
      end
    end)

    Dir.mktmpdir do |dir|
      Dir.chdir(dir) do
        FileUtils.mkdir_p('spec/factories')

        instance = klass.new(['Models::Comment'])
        instance.generate_factory

        factory_file = File.join('spec/factories/comment.rb')
        content = File.read(factory_file)

        expect(content).to include('body')
        expect(content).not_to include('user_id')
        expect(content).not_to include('post_id')
        expect(content).not_to include('author_id')
      end
    end
  end

  it 'raises error when model not found' do
    Dir.mktmpdir do |dir|
      Dir.chdir(dir) do
        instance = klass.new(['Models::NonExistent'])
        expect { instance.generate_factory }
          .to raise_error(Thor::Error)
      end
    end
  end

  it 'generates factory with static values when --static option is used' do
    stub_const('Models', Module.new)
    stub_const('Models::User', Class.new do
      def self.columns
        [
          Struct.new(:name, :type).new('id', :integer),
          Struct.new(:name, :type).new('full_name', :string),
          Struct.new(:name, :type).new('email', :string),
          Struct.new(:name, :type).new('age', :integer),
          Struct.new(:name, :type).new('active', :boolean),
          Struct.new(:name, :type).new('created_at', :datetime),
          Struct.new(:name, :type).new('updated_at', :datetime)
        ]
      end
    end)

    Dir.mktmpdir do |dir|
      Dir.chdir(dir) do
        FileUtils.mkdir_p('spec/factories')

        instance = klass.new(['Models::User'], {}, {})
        instance.options = { static: true }
        instance.generate_factory

        factory_file = File.join('spec/factories/user.rb')
        content = File.read(factory_file)

        expect(content).to include('full_name')
        expect(content).to include('email')
        expect(content).to include('age')
        expect(content).to include('active')
        # Static values should be quoted strings or literal values, not Faker calls
        expect(content).not_to include('Faker::')
        # Should contain actual static values
        expect(content).to match(/full_name \{ '[^']+' \}/)
        expect(content).to match(/email \{ '[^']+@[^']+' \}/)
      end
    end
  end

  it 'keeps Time.zone.now for time fields even with --static option' do
    stub_const('Models', Module.new)
    stub_const('Models::Event', Class.new do
      def self.columns
        [
          Struct.new(:name, :type).new('id', :integer),
          Struct.new(:name, :type).new('title', :string),
          Struct.new(:name, :type).new('start_time', :datetime),
          Struct.new(:name, :type).new('end_time', :timestamp),
          Struct.new(:name, :type).new('reminder_time', :time),
          Struct.new(:name, :type).new('created_at', :datetime),
          Struct.new(:name, :type).new('updated_at', :datetime)
        ]
      end
    end)

    Dir.mktmpdir do |dir|
      Dir.chdir(dir) do
        FileUtils.mkdir_p('spec/factories')

        instance = klass.new(['Models::Event'], {}, {})
        instance.options = { static: true }
        instance.generate_factory

        factory_file = File.join('spec/factories/event.rb')
        content = File.read(factory_file)

        # Title should be static
        expect(content).to match(/title \{ '[^']+' \}/)

        # Time fields should NOT be static, should remain Time.zone.now
        expect(content).to include('start_time { Time.zone.now }')
        expect(content).to include('end_time { Time.zone.now }')
        expect(content).to include('reminder_time { Time.zone.now }')

        # Should not contain static datetime strings
        expect(content).not_to match(/start_time \{ '[0-9]{4}-[0-9]{2}-[0-9]{2}/)
        expect(content).not_to match(/end_time \{ '[0-9]{4}-[0-9]{2}-[0-9]{2}/)
      end
    end
  end
end
