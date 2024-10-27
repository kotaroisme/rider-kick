# frozen_string_literal: true

require 'spec_helper'

RSpec.describe RiderKick::Builders::AbstractActiveRecordEntityBuilder do
  let(:entity_class) do
    Class.new(Dry::Struct) do
      attribute :id, Types::String
      attribute :name, Types::String
      attribute :related_entities, Types::Array.of(Types::Hash).optional.default([].freeze)
      attribute :other_entity, Types::Hash.optional.default(nil)
    end
  end

  let(:builder_class) do
    entity = entity_class
    Class.new(described_class) do
      acts_as_builder_for_entity(entity)
    end
  end

  let(:params) { instance_double('ActiveRecord::Base', attributes: { 'id' => '123e4567-e89b-12d3-a456-426614174000', 'name' => 'Sample Name' }) }
  let(:extra_param1) { 'extra1' }
  let(:extra_param2) { 'extra2' }

  subject(:builder) { builder_class.new(params, extra_param1, extra_param2) }

  describe '#initialize' do
    it 'initializes with params and extra arguments' do
      expect { builder_class.new(params, extra_param1, extra_param2) }.not_to raise_error
      expect(builder.instance_variable_get(:@params)).to eq(params)
      expect(builder.instance_variable_get(:@args)).to eq([extra_param1, extra_param2])
    end
  end

  describe '.acts_as_builder_for_entity' do
    it 'sets entity class as a private method' do
      expect(builder.send(:entity_class)).to eq(entity_class)
    end
  end

  describe '.has_many' do
    let(:related_entity_class) { double('RelatedEntityClass') }
    let(:relation_name) { :related_entities }

    before do
      builder_class.has_many relation_name, use: related_entity_class
      allow(params).to receive(relation_name).and_return([double('Relation')])
      allow(related_entity_class).to receive(:new).and_return(double(build: { id: 'abc123', name: 'Related' }))
    end

    it 'adds to has_many_builders' do
      expect(builder_class.has_many_builders).to include([relation_name, related_entity_class])
    end

    it 'builds has_many relations' do
      result = builder.send(:attributes_for_has_many_relations)
      expect(result[relation_name]).to eq([{ id: 'abc123', name: 'Related' }])
    end
  end

  describe '.belongs_to' do
    let(:other_entity_class) { double('OtherEntityClass') }
    let(:relation_name) { :other_entity }

    before do
      builder_class.belongs_to relation_name, use: other_entity_class
      allow(params).to receive(relation_name).and_return(double('Relation'))
      allow(other_entity_class).to receive(:new).and_return(double(build: { id: 'xyz789', name: 'Other' }))
    end

    it 'adds to belongs_to_builders' do
      expect(builder_class.belongs_to_builders).to include([relation_name, other_entity_class])
    end

    it 'builds belongs_to relation' do
      result = builder.send(:attributes_for_belongs_to_relations)
      expect(result[relation_name]).to eq({ id: 'xyz789', name: 'Other' })
    end
  end

  describe '#build' do
    let(:attributes) { { id: '123e4567-e89b-12d3-a456-426614174000', name: 'Sample Name' } }

    it 'builds the entity with AR attributes' do
      allow(builder).to receive(:ar_attributes_for_entity).and_return(attributes)
      entity = builder.build
      expect(entity.id).to eq('123e4567-e89b-12d3-a456-426614174000')
      expect(entity.name).to eq('Sample Name')
    end

    context 'when has_many and belongs_to relations exist' do
      let(:related_entity_class) { double('RelatedEntityClass') }
      let(:other_entity_class) { double('OtherEntityClass') }

      before do
        builder_class.has_many :related_entities, use: related_entity_class
        builder_class.belongs_to :other_entity, use: other_entity_class

        allow(params).to receive(:related_entities).and_return([double('Relation')])
        allow(params).to receive(:other_entity).and_return(double('Relation'))

        allow(related_entity_class).to receive(:new).and_return(double(build: { id: 'abc123', name: 'Related' }))
        allow(other_entity_class).to receive(:new).and_return(double(build: { id: 'xyz789', name: 'Other' }))
      end

      it 'builds the entity with all attributes' do
        entity = builder.build
        expect(entity.id).to eq('123e4567-e89b-12d3-a456-426614174000')
        expect(entity.name).to eq('Sample Name')
        expect(entity.related_entities).to eq([{ id: 'abc123', name: 'Related' }])
        expect(entity.other_entity).to eq({ id: 'xyz789', name: 'Other' })
      end
    end
  end
end
