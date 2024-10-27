# typed: false
# frozen_string_literal: true

module RiderKick
  module Builders
    # Helps to take an instance of an AR model and wrap it up in the given Entity
    # Any columns from the AR model that do not directly map to an attribute on the Entity
    # can be specified by overriding #attributes_for_entity.
    class AbstractActiveRecordEntityBuilder
      # @param [Class] A Dry::Struct based entity that this builder will construct instances of
      def self.acts_as_builder_for_entity(entity_class)
        @has_many_builders   = []
        @belongs_to_builders = []

        define_singleton_method :has_many_builders do
          @has_many_builders
        end

        define_singleton_method :belongs_to_builders do
          @belongs_to_builders
        end

        define_method :entity_class do
          entity_class
        end

        private :entity_class
      end

      def self.has_many(relation_name, use:)
        @has_many_builders << [relation_name, use]
      end

      def self.belongs_to(relation_name, use:)
        @belongs_to_builders << [relation_name, use]
      end

      # @param [ActiveRecord::Base] An ActiveRecord model to map to the entity
      def initialize(params, *args)
        @params = params
        @args   = args
      end

      def build
        entity_class.new(all_attributes_for_entity)
      end

      private

      attr_reader :params
      attr_reader :args

      def entity_attribute_names
        @entity_attributes ||= begin
                                 if entity_class.respond_to?(:schema) # Dry::Struct
                                   schema_keys = entity_class.schema.keys
                                 elsif entity_class.respond_to?(:decorator) # T::Struct
                                   schema_keys = entity_class.decorator.props.keys
                                 else
                                   raise 'Cannot determine schema format'
                                 end
                                 first_key = schema_keys.first
                                 if first_key.is_a?(Symbol)
                                   schema_keys
                                 elsif first_key.respond_to?(:name)
                                   schema_keys.map(&:name)
                                 else
                                   raise 'Cannot determine schema format'
                                 end
                               end
      end

      def params_attributes
        @params_attributes ||= @params.attributes
      end

      def symbolized_params_attributes
        @symbolized_params_attributes ||= Hash[
          params_attributes.map { |(key, value)| [key.to_sym, value] }
        ]
      end

      def ar_attributes_for_entity
        symbolized_params_attributes.slice(*entity_attribute_names)
      end

      def attributes_for_belongs_to_relations
        self.class.belongs_to_builders.map do |belongs_to_builder_config|
          relation_name, builder_class = belongs_to_builder_config
          relation                     = @params.public_send(relation_name)

          [
            relation_name,
            relation ? builder_class.new(relation).build : nil
          ]
        end.to_h
      end

      def attributes_for_has_many_relations
        self.class.has_many_builders.map do |has_many_builder_config|
          relation_name, builder_class = has_many_builder_config
          relations                    = @params.public_send(relation_name)
          built_relations              = relations.map do |relation|
            builder_class.new(relation).build
          end

          [
            relation_name,
            built_relations
          ]
        end.to_h
      end

      def attributes_for_entity
        {}
      end

      def all_attributes_for_entity
        ar_attributes_for_entity
          .merge(attributes_for_belongs_to_relations)
          .merge(attributes_for_has_many_relations)
          .merge(attributes_for_entity)
      end
    end
  end
end
