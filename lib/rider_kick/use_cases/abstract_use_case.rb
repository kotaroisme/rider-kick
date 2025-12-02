# typed: true
# frozen_string_literal: true

require 'dry/monads/result'
require 'dry/validation'
require 'dry/matcher/result_matcher'
require_relative 'contract'

module RiderKick
  module UseCases
    class AbstractUseCase
      include Dry::Monads[:result]

      def self.contract(base_contract = Contract, &proc)
        @contract ||= Class.new(base_contract, &proc)
      end

      def self.contract!(args)
        context  = args.fetch(:context, {})
        @results = @contract.new(context).call(args)
      end

      def initialize(contract)
        @contract = contract
      end

      def build_parameter!
        if @contract.success?
          Success(Hashie::Mash.new(@contract.to_h))
        else
          Failure(@contract.errors.to_h)
        end
      end
    end
  end
end
