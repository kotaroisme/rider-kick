# typed: false
# frozen_string_literal: true

require 'rider_kick/types'
require 'dry/struct'

module RiderKick
  module Entities
    class FailureDetails < Dry::Struct
      failure_types = Types::Strict::String.enum(
                        'error',
                        'expectation_failed',
                        'not_found',
                        'unauthorized',
                        'unprocessable_entity'
      )
      attribute :type, failure_types
      attribute :message, Types::Strict::String
      attribute :other_properties, Types::Strict::Hash.default({}.freeze)

      def self.from_array(array)
        new(message: 'failure 1, failure 2', other_properties: {}, type: 'error')
      end

      def self.from_string(string)
        new(message: string, other_properties: {}, type: 'error')
      end
    end
  end
end
