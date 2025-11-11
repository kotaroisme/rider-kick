# frozen_string_literal: true

require_relative '../types'
require 'dry/struct'

module RiderKick
  module Entities
    class FailureDetails < Dry::Struct
      # enum + default HARUS: default dulu, baru enum (sesuai dry-types)
      TYPE = Types::Coercible::Symbol
        .default(:error)
        .enum(:error, :expectation_failed, :not_found, :unauthorized, :unprocessable_entity)
      private_constant :TYPE

      attribute :type,             TYPE
      attribute :message,          Types::Strict::String
      attribute :other_properties, Types::Strict::Hash.default({}.freeze)

      # Kumpulkan array pesan jadi satu kalimat, type default :error
      def self.from_array(array, type: :error, **extras)
        new(
          type:             type,
          message:          Array(array).map!(&:to_s).join(', '),
          other_properties: extras
        )
      end

      # Bungkus string jadi FailureDetails, type default :error
      def self.from_string(string, type: :error, **extras)
        new(
          type:             type,
          message:          string.to_s,
          other_properties: extras
        )
      end
    end
  end
end
