# frozen_string_literal: true

require 'dry-struct'
require 'active_support/core_ext/time'
require 'rider_kick/builders/abstract_active_record_entity_builder'

RSpec.describe RiderKick::Builders::AbstractActiveRecordEntityBuilder do
  # Create a test entity class using Dry::Struct
  module Types
    include Dry.Types()
  end

  # Create entity class outside of let block so it's available in Class.new blocks
  test_entity_class = Class.new(Dry::Struct) do
    attribute :id, Types::String
    attribute :name, Types::String.optional
    attribute :email, Types::String.optional
  end

  let(:test_entity_class) { test_entity_class }

  # Create a mock ActiveRecord model
  let(:mock_ar_model) do
    double('ActiveRecord::Base').tap do |model|
      allow(model).to receive(:attributes).and_return({
        'id' => '123',
        'name' => 'Test User',
        'email' => 'test@example.com',
        'created_at' => Time.current,
        'updated_at' => Time.current
      })
    end
  end

  describe '.acts_as_builder_for_entity' do
    let(:builder_class) do
      entity_class = test_entity_class
      Class.new(described_class) do
        acts_as_builder_for_entity(entity_class)
      end
    end

    it 'sets @has_many_builders and @belongs_to_builders to empty arrays' do
      expect(builder_class.has_many_builders).to eq([])
      expect(builder_class.belongs_to_builders).to eq([])
    end

    it 'defines singleton method has_many_builders' do
      expect(builder_class).to respond_to(:has_many_builders)
      expect(builder_class.has_many_builders).to be_an(Array)
    end

    it 'defines singleton method belongs_to_builders' do
      expect(builder_class).to respond_to(:belongs_to_builders)
      expect(builder_class.belongs_to_builders).to be_an(Array)
    end

    it 'defines instance method entity_class' do
      builder = builder_class.new(mock_ar_model)
      expect(builder.send(:entity_class)).to eq(test_entity_class)
    end

    it 'makes entity_class private' do
      builder = builder_class.new(mock_ar_model)
      expect { builder.entity_class }.to raise_error(NoMethodError)
    end
  end

  describe '.has_many' do
    let(:builder_class) do
      entity_class = test_entity_class
      Class.new(described_class) do
        acts_as_builder_for_entity(entity_class)
      end
    end

    let(:relation_builder_class) do
      entity_class = test_entity_class
      Class.new(described_class) do
        acts_as_builder_for_entity(entity_class)
      end
    end

    it 'adds to @has_many_builders array' do
      builder_class.has_many(:comments, use: relation_builder_class)
      expect(builder_class.has_many_builders.length).to eq(1)
    end

    it 'stores attribute_as, relation_name, and use' do
      builder_class.has_many(:comments, attribute_as: :comment_list, use: relation_builder_class)
      config = builder_class.has_many_builders.first
      expect(config).to eq([:comment_list, :comments, relation_builder_class])
    end

    it 'uses relation_name when attribute_as is nil' do
      builder_class.has_many(:comments, use: relation_builder_class)
      config = builder_class.has_many_builders.first
      expect(config[0]).to be_nil
      expect(config[1]).to eq(:comments)
    end

    it 'handles multiple has_many declarations' do
      builder_class.has_many(:comments, use: relation_builder_class)
      builder_class.has_many(:tags, use: relation_builder_class)
      expect(builder_class.has_many_builders.length).to eq(2)
    end
  end

  describe '.belongs_to' do
    let(:builder_class) do
      entity_class = test_entity_class
      Class.new(described_class) do
        acts_as_builder_for_entity(entity_class)
      end
    end

    let(:relation_builder_class) do
      entity_class = test_entity_class
      Class.new(described_class) do
        acts_as_builder_for_entity(entity_class)
      end
    end

    it 'adds to @belongs_to_builders array' do
      builder_class.belongs_to(:user, use: relation_builder_class)
      expect(builder_class.belongs_to_builders.length).to eq(1)
    end

    it 'stores attribute_as, relation_name, and use' do
      builder_class.belongs_to(:user, attribute_as: :author, use: relation_builder_class)
      config = builder_class.belongs_to_builders.first
      expect(config).to eq([:author, :user, relation_builder_class])
    end

    it 'uses relation_name when attribute_as is nil' do
      builder_class.belongs_to(:user, use: relation_builder_class)
      config = builder_class.belongs_to_builders.first
      expect(config[0]).to be_nil
      expect(config[1]).to eq(:user)
    end

    it 'handles multiple belongs_to declarations' do
      builder_class.belongs_to(:user, use: relation_builder_class)
      builder_class.belongs_to(:account, use: relation_builder_class)
      expect(builder_class.belongs_to_builders.length).to eq(2)
    end
  end

  describe '#initialize' do
    let(:builder_class) do
      Class.new(described_class) do
        acts_as_builder_for_entity(test_entity_class)
      end
    end

    it 'sets @params' do
      builder = builder_class.new(mock_ar_model)
      expect(builder.send(:params)).to eq(mock_ar_model)
    end

    it 'sets @args' do
      builder = builder_class.new(mock_ar_model, 'arg1', 'arg2')
      expect(builder.send(:args)).to eq(['arg1', 'arg2'])
    end

    it 'handles no additional args' do
      builder = builder_class.new(mock_ar_model)
      expect(builder.send(:args)).to eq([])
    end
  end

  describe '#build' do
    let(:builder_class) do
      entity_class = test_entity_class
      Class.new(described_class) do
        acts_as_builder_for_entity(entity_class)
      end
    end

    it 'calls entity_class.new with all_attributes_for_entity' do
      builder = builder_class.new(mock_ar_model)
      attributes = builder.send(:all_attributes_for_entity)
      expect(test_entity_class).to receive(:new).with(attributes)
      builder.build
    end

    it 'returns entity instance' do
      builder = builder_class.new(mock_ar_model)
      entity = builder.build
      expect(entity).to be_a(test_entity_class)
      expect(entity.id).to eq('123')
    end
  end

  describe '#entity_attribute_names' do
    let(:builder_class) do
      entity_class = test_entity_class
      Class.new(described_class) do
        acts_as_builder_for_entity(entity_class)
      end
    end

    context 'with Dry::Struct schema' do
      it 'detects Dry::Struct schema' do
        builder = builder_class.new(mock_ar_model)
        attribute_names = builder.send(:entity_attribute_names)
        expect(attribute_names).to include(:id, :name, :email)
      end

      it 'returns symbol keys' do
        builder = builder_class.new(mock_ar_model)
        attribute_names = builder.send(:entity_attribute_names)
        expect(attribute_names.all? { |k| k.is_a?(Symbol) }).to be true
      end

      it 'caches the result' do
        builder = builder_class.new(mock_ar_model)
        first_call = builder.send(:entity_attribute_names)
        second_call = builder.send(:entity_attribute_names)
        expect(first_call.object_id).to eq(second_call.object_id)
      end
    end

    context 'with T::Struct schema (decorator)' do
      let(:t_struct_entity_class) do
        decorator_props = {
          id: double('Prop', name: :id),
          name: double('Prop', name: :name)
        }
        decorator = double('Decorator')
        allow(decorator).to receive(:props).and_return(decorator_props)
        
        Class.new do
          define_singleton_method(:decorator) { decorator }
        end
      end

      let(:t_struct_builder_class) do
        entity_class = t_struct_entity_class
        Class.new(described_class) do
          acts_as_builder_for_entity(entity_class)
        end
      end

      it 'detects T::Struct schema via decorator' do
        builder = t_struct_builder_class.new(mock_ar_model)
        attribute_names = builder.send(:entity_attribute_names)
        expect(attribute_names).to include(:id, :name)
      end

      it 'extracts names from props with .name method' do
        builder = t_struct_builder_class.new(mock_ar_model)
        attribute_names = builder.send(:entity_attribute_names)
        expect(attribute_names.all? { |k| k.is_a?(Symbol) }).to be true
      end
    end

    context 'with unknown schema format' do
      let(:unknown_entity_class) do
        Class.new do
          # No schema or decorator methods
        end
      end

      let(:unknown_builder_class) do
        entity_class = unknown_entity_class
        Class.new(described_class) do
          acts_as_builder_for_entity(entity_class)
        end
      end

      it 'raises error for unknown schema format' do
        builder = unknown_builder_class.new(mock_ar_model)
        expect {
          builder.send(:entity_attribute_names)
        }.to raise_error('Cannot determine schema format')
      end
    end

    context 'with keys that respond to .name' do
      let(:name_key_entity_class) do
        # Schema should return a hash where keys have .name method
        key1 = double('Key', name: :id)
        key2 = double('Key', name: :name)
        schema_mock = double('Schema')
        allow(schema_mock).to receive(:keys).and_return([key1, key2])
        
        Class.new do
          define_singleton_method(:schema) { schema_mock }
        end
      end

      let(:name_key_builder_class) do
        entity_class = name_key_entity_class
        Class.new(described_class) do
          acts_as_builder_for_entity(entity_class)
        end
      end

      it 'extracts names from keys with .name method' do
        builder = name_key_builder_class.new(mock_ar_model)
        attribute_names = builder.send(:entity_attribute_names)
        expect(attribute_names).to include(:id, :name)
      end
    end
  end

  describe '#params_attributes' do
    let(:builder_class) do
      entity_class = test_entity_class
      Class.new(described_class) do
        acts_as_builder_for_entity(entity_class)
      end
    end

    it 'returns @params.attributes' do
      builder = builder_class.new(mock_ar_model)
      attributes = builder.send(:params_attributes)
      expect(attributes).to eq(mock_ar_model.attributes)
    end

    it 'caches the result' do
      builder = builder_class.new(mock_ar_model)
      first_call = builder.send(:params_attributes)
      second_call = builder.send(:params_attributes)
      expect(first_call.object_id).to eq(second_call.object_id)
    end
  end

  describe '#symbolized_params_attributes' do
    let(:builder_class) do
      entity_class = test_entity_class
      Class.new(described_class) do
        acts_as_builder_for_entity(entity_class)
      end
    end

    it 'converts keys to symbols' do
      builder = builder_class.new(mock_ar_model)
      symbolized = builder.send(:symbolized_params_attributes)
      expect(symbolized.keys.all? { |k| k.is_a?(Symbol) }).to be true
    end

    it 'returns hash with symbol keys' do
      builder = builder_class.new(mock_ar_model)
      symbolized = builder.send(:symbolized_params_attributes)
      expect(symbolized).to be_a(Hash)
      expect(symbolized[:id]).to eq('123')
      expect(symbolized[:name]).to eq('Test User')
    end

    it 'caches the result' do
      builder = builder_class.new(mock_ar_model)
      first_call = builder.send(:symbolized_params_attributes)
      second_call = builder.send(:symbolized_params_attributes)
      expect(first_call.object_id).to eq(second_call.object_id)
    end
  end

  describe '#ar_attributes_for_entity' do
    let(:builder_class) do
      entity_class = test_entity_class
      Class.new(described_class) do
        acts_as_builder_for_entity(entity_class)
      end
    end

    it 'slices attributes based on entity_attribute_names' do
      builder = builder_class.new(mock_ar_model)
      ar_attributes = builder.send(:ar_attributes_for_entity)
      expect(ar_attributes.keys).to all(satisfy { |k| [:id, :name, :email].include?(k) })
    end

    it 'returns only matching attributes' do
      builder = builder_class.new(mock_ar_model)
      ar_attributes = builder.send(:ar_attributes_for_entity)
      expect(ar_attributes).to include(id: '123', name: 'Test User', email: 'test@example.com')
      expect(ar_attributes).not_to have_key(:created_at)
      expect(ar_attributes).not_to have_key(:updated_at)
    end
  end

  describe '#attributes_for_belongs_to_relations' do
    let(:related_entity_class) do
      Class.new(Dry::Struct) do
        attribute :id, Types::String
        attribute :name, Types::String
      end
    end

    let(:related_builder_class) do
      entity_class = related_entity_class
      Class.new(described_class) do
        acts_as_builder_for_entity(entity_class)
      end
    end

    let(:builder_class) do
      entity_class = test_entity_class
      related_builder = related_builder_class
      Class.new(described_class) do
        acts_as_builder_for_entity(entity_class)
        belongs_to :user, use: related_builder
      end
    end

    it 'maps belongs_to builders' do
      related_model = double('User', attributes: { 'id' => '456', 'name' => 'Related User' })
      ar_model = double('Article', attributes: { 'id' => '123' })
      allow(ar_model).to receive(:user).and_return(related_model)

      builder = builder_class.new(ar_model)
      attributes = builder.send(:attributes_for_belongs_to_relations)
      expect(attributes).to have_key(:user)
      expect(attributes[:user]).to be_a(related_entity_class)
    end

    it 'handles nil relations' do
      ar_model = double('Article', attributes: { 'id' => '123' })
      allow(ar_model).to receive(:user).and_return(nil)

      builder = builder_class.new(ar_model)
      attributes = builder.send(:attributes_for_belongs_to_relations)
      expect(attributes[:user]).to be_nil
    end

      it 'uses attribute_as when provided' do
      entity_class = test_entity_class
      related_builder = related_builder_class
      builder_class_with_alias = Class.new(described_class) do
        acts_as_builder_for_entity(entity_class)
        belongs_to :user, attribute_as: :author, use: related_builder
      end

      related_model = double('User', attributes: { 'id' => '456', 'name' => 'Related User' })
      ar_model = double('Article', attributes: { 'id' => '123' })
      allow(ar_model).to receive(:user).and_return(related_model)

      builder = builder_class_with_alias.new(ar_model)
      attributes = builder.send(:attributes_for_belongs_to_relations)
      expect(attributes).to have_key(:author)
      expect(attributes).not_to have_key(:user)
    end

    it 'uses relation_name when attribute_as is nil' do
      related_model = double('User', attributes: { 'id' => '456', 'name' => 'Related User' })
      ar_model = double('Article', attributes: { 'id' => '123' })
      allow(ar_model).to receive(:user).and_return(related_model)

      builder = builder_class.new(ar_model)
      attributes = builder.send(:attributes_for_belongs_to_relations)
      expect(attributes).to have_key(:user)
    end
  end

  describe '#attributes_for_has_many_relations' do
    let(:comment_entity_class) do
      Class.new(Dry::Struct) do
        attribute :id, Types::String
        attribute :content, Types::String
      end
    end

    let(:comment_builder_class) do
      entity_class = comment_entity_class
      Class.new(described_class) do
        acts_as_builder_for_entity(entity_class)
      end
    end

    let(:builder_class) do
      entity_class = test_entity_class
      comment_builder = comment_builder_class
      Class.new(described_class) do
        acts_as_builder_for_entity(entity_class)
        has_many :comments, use: comment_builder
      end
    end

    it 'maps has_many builders' do
      comment1 = double('Comment', attributes: { 'id' => '1', 'content' => 'Comment 1' })
      comment2 = double('Comment', attributes: { 'id' => '2', 'content' => 'Comment 2' })
      ar_model = double('Article', attributes: { 'id' => '123' })
      allow(ar_model).to receive(:comments).and_return([comment1, comment2])

      builder = builder_class.new(ar_model)
      attributes = builder.send(:attributes_for_has_many_relations)
      expect(attributes).to have_key(:comments)
      expect(attributes[:comments]).to be_an(Array)
      expect(attributes[:comments].length).to eq(2)
      expect(attributes[:comments].all? { |c| c.is_a?(comment_entity_class) }).to be true
    end

    it 'builds multiple relations' do
      comment1 = double('Comment', attributes: { 'id' => '1', 'content' => 'Comment 1' })
      comment2 = double('Comment', attributes: { 'id' => '2', 'content' => 'Comment 2' })
      ar_model = double('Article', attributes: { 'id' => '123' })
      allow(ar_model).to receive(:comments).and_return([comment1, comment2])

      builder = builder_class.new(ar_model)
      attributes = builder.send(:attributes_for_has_many_relations)
      expect(attributes[:comments].first.id).to eq('1')
      expect(attributes[:comments].last.id).to eq('2')
    end

    it 'uses attribute_as when provided' do
      entity_class = test_entity_class
      comment_builder = comment_builder_class
      builder_class_with_alias = Class.new(described_class) do
        acts_as_builder_for_entity(entity_class)
        has_many :comments, attribute_as: :comment_list, use: comment_builder
      end

      comment1 = double('Comment', attributes: { 'id' => '1', 'content' => 'Comment 1' })
      ar_model = double('Article', attributes: { 'id' => '123' })
      allow(ar_model).to receive(:comments).and_return([comment1])

      builder = builder_class_with_alias.new(ar_model)
      attributes = builder.send(:attributes_for_has_many_relations)
      expect(attributes).to have_key(:comment_list)
      expect(attributes).not_to have_key(:comments)
    end

    it 'uses relation_name when attribute_as is nil' do
      comment1 = double('Comment', attributes: { 'id' => '1', 'content' => 'Comment 1' })
      ar_model = double('Article', attributes: { 'id' => '123' })
      allow(ar_model).to receive(:comments).and_return([comment1])

      builder = builder_class.new(ar_model)
      attributes = builder.send(:attributes_for_has_many_relations)
      expect(attributes).to have_key(:comments)
    end
  end

  describe '#attributes_for_entity' do
    let(:builder_class) do
      entity_class = test_entity_class
      Class.new(described_class) do
        acts_as_builder_for_entity(entity_class)
      end
    end

    it 'returns empty hash (default implementation)' do
      builder = builder_class.new(mock_ar_model)
      attributes = builder.send(:attributes_for_entity)
      expect(attributes).to eq({})
    end
  end

  describe '#all_attributes_for_entity' do
    let(:related_entity_class) do
      Class.new(Dry::Struct) do
        attribute :id, Types::String
        attribute :name, Types::String
      end
    end

    let(:comment_entity_class) do
      Class.new(Dry::Struct) do
        attribute :id, Types::String
        attribute :content, Types::String
      end
    end

    let(:related_builder_class) do
      entity_class = related_entity_class
      Class.new(described_class) do
        acts_as_builder_for_entity(entity_class)
      end
    end

    let(:comment_builder_class) do
      entity_class = comment_entity_class
      Class.new(described_class) do
        acts_as_builder_for_entity(entity_class)
      end
    end

    let(:builder_class) do
      entity_class = test_entity_class
      related_builder = related_builder_class
      comment_builder = comment_builder_class
      Class.new(described_class) do
        acts_as_builder_for_entity(entity_class)
        belongs_to :user, use: related_builder
        has_many :comments, use: comment_builder
      end
    end

    it 'merges all attribute sources' do
      related_model = double('User', attributes: { 'id' => '456', 'name' => 'Related User' })
      comment1 = double('Comment', attributes: { 'id' => '1', 'content' => 'Comment 1' })
      ar_model = double('Article', attributes: { 'id' => '123', 'name' => 'Article', 'email' => 'article@example.com' })
      allow(ar_model).to receive(:user).and_return(related_model)
      allow(ar_model).to receive(:comments).and_return([comment1])

      builder = builder_class.new(ar_model)
      all_attributes = builder.send(:all_attributes_for_entity)
      
      expect(all_attributes).to have_key(:id)
      expect(all_attributes).to have_key(:name)
      expect(all_attributes).to have_key(:email)
      expect(all_attributes).to have_key(:user)
      expect(all_attributes).to have_key(:comments)
    end

    it 'merges in correct order: ar_attributes → belongs_to → has_many → custom' do
      related_model = double('User', attributes: { 'id' => '456', 'name' => 'Related User' })
      comment1 = double('Comment', attributes: { 'id' => '1', 'content' => 'Comment 1' })
      ar_model = double('Article', attributes: { 'id' => '123', 'name' => 'Article', 'email' => 'article@example.com' })
      allow(ar_model).to receive(:user).and_return(related_model)
      allow(ar_model).to receive(:comments).and_return([comment1])

      # Create custom builder class that inherits from builder_class
      # Need to ensure it has the same configuration
      entity_class = test_entity_class
      related_builder = related_builder_class
      comment_builder = comment_builder_class
      custom_builder_class = Class.new(described_class) do
        acts_as_builder_for_entity(entity_class)
        belongs_to :user, use: related_builder
        has_many :comments, use: comment_builder
        
        define_method(:attributes_for_entity) do
          { custom_field: 'custom_value' }
        end
      end

      builder = custom_builder_class.new(ar_model)
      all_attributes = builder.send(:all_attributes_for_entity)
      
      # Custom attributes should be last (override previous)
      expect(all_attributes[:custom_field]).to eq('custom_value')
      # AR attributes should be present
      expect(all_attributes[:id]).to eq('123')
      expect(all_attributes[:name]).to eq('Article')
      expect(all_attributes[:email]).to eq('article@example.com')
      # Relations should be present
      expect(all_attributes[:user]).to be_a(related_entity_class)
      expect(all_attributes[:comments]).to be_an(Array)
      expect(all_attributes[:comments].first).to be_a(comment_entity_class)
    end
  end
end

