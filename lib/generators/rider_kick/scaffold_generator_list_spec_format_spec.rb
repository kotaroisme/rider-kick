# frozen_string_literal: true

require 'rails/generators'
require 'tmpdir'
require 'generators/rider_kick/scaffold_generator'

RSpec.describe 'rider_kick:scaffold list spec generation' do
  let(:klass) { RiderKick::ScaffoldGenerator }

  it 'generates list spec with resource_owner_id' do
    stub_const('Models', Module.new)
    stub_const('Models::Article', Class.new do
      def self.columns
        [
          Struct.new(:name, :type).new('id', :integer),
          Struct.new(:name, :type).new('title', :string),
          Struct.new(:name, :type).new('content', :text),
          Struct.new(:name, :type).new('account_id', :string),
          Struct.new(:name, :type).new('user_id', :integer),
          Struct.new(:name, :type).new('created_at', :datetime),
          Struct.new(:name, :type).new('updated_at', :datetime)
        ]
      end

      def self.column_names
        ['id', 'title', 'content', 'account_id', 'user_id', 'created_at', 'updated_at']
      end

      def self.columns_hash
        {
          'title'      => Struct.new(:type).new(:string),
          'content'    => Struct.new(:type).new(:text),
          'account_id' => Struct.new(:type).new(:string),
          'user_id'    => Struct.new(:type).new(:integer)
        }
      end
    end)

    Dir.mktmpdir do |dir|
      Dir.chdir(dir) do
        FileUtils.mkdir_p('app/domains')
        FileUtils.mkdir_p('db/structures')

        # Create structure YAML
        structure_yaml = <<~YAML
          model: Models::Article
          resource_name: article
          actor: owner
          resource_owner_id: account_id
          domains:
            action_list:
              use_case:
                contract: []
              repository:
                filters:
                  - "{ field: 'title', type: 'search' }"
        YAML

        File.write('db/structures/articles_structure.yaml', structure_yaml)

        instance = klass.new(['articles', { 'scope' => 'dashboard' }])

        # Mock methods
        allow(instance).to receive(:say)
        allow(instance).to receive(:empty_directory)
        allow(RiderKick.configuration).to receive(:domains_path).and_return('app/domains')

        instance.generate_use_case

        list_spec_file = 'app/domains/repositories/articles/list_article_spec.rb'
        expect(File.exist?(list_spec_file)).to be true

        content = File.read(list_spec_file)

        # Verify format matches user's requirements
        expect(content).to include('let(:repository) { described_class }')
        expect(content).to include('repository.new(params: params).call')
        expect(content).to include('account_id: SecureRandom.uuid')
        expect(content).to include('create_list(:article, 3, account_id: params[:account_id])')
        expect(content).to include('context \'with search filters\'')
        expect(content).to include('context \'with resource owner filter\'')
        expect(content).to include('context \'with sorting\'')
      end
    end
  end

  it 'generates list spec without resource_owner_id' do
    stub_const('Models', Module.new)
    stub_const('Models::Product', Class.new do
      def self.columns
        [
          Struct.new(:name, :type).new('id', :integer),
          Struct.new(:name, :type).new('name', :string),
          Struct.new(:name, :type).new('price', :decimal),
          Struct.new(:name, :type).new('created_at', :datetime),
          Struct.new(:name, :type).new('updated_at', :datetime)
        ]
      end

      def self.column_names
        ['id', 'name', 'price', 'created_at', 'updated_at']
      end

      def self.columns_hash
        {
          'name'  => double(type: :string),
          'price' => double(type: :decimal)
        }
      end
    end)

    Dir.mktmpdir do |dir|
      Dir.chdir(dir) do
        FileUtils.mkdir_p('app/domains')
        FileUtils.mkdir_p('db/structures')

        structure_yaml = <<~YAML
          model: Models::Product
          resource_name: product
          actor: admin
          domains:
            action_list:
              use_case:
                contract: []
              repository:
                filters: []
        YAML

        File.write('db/structures/products_structure.yaml', structure_yaml)

        instance = klass.new(['products', { 'scope' => 'admin' }])

        allow(instance).to receive(:say)
        allow(instance).to receive(:empty_directory)
        allow(RiderKick.configuration).to receive(:domains_path).and_return('app/domains')

        instance.generate_use_case

        list_spec_file = 'app/domains/repositories/products/list_product_spec.rb'
        expect(File.exist?(list_spec_file)).to be true

        content = File.read(list_spec_file)

        # Verify format without resource_owner_id
        expect(content).to include('let(:repository) { described_class }')
        expect(content).to include('repository.new(params: params).call')
        expect(content).to include('create_list(:product, 3)')
        expect(content).not_to include('account_id')
        expect(content).not_to include('user_id')
      end
    end
  end
end
