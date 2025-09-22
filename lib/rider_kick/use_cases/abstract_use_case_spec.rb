# frozen_string_literal: true

require 'dry/validation'
require 'rider_kick/use_cases/abstract_use_case'

RSpec.describe RiderKick::UseCases::AbstractUseCase do
  # Use case dummy untuk menguji .contract, .contract! dan build_parameter!
  class DummyUseCase < RiderKick::UseCases::AbstractUseCase
    contract do
      params do
        required(:name).filled(:string)
        optional(:age).maybe(:integer)
      end
    end

    include Dry::Monads::Do.for(:result)
    def result
      params = yield build_parameter!
      Success(params)
    end
  end

  describe '.contract/.contract!' do
    it 'membangun dan menjalankan contract' do
      contract = DummyUseCase.contract!(name: 'Kotaro')
      expect(contract).to be_success
    end
  end

  describe '#build_parameter!' do
    it 'mengembalikan Success(Hashie::Mash) ketika valid' do
      contract = DummyUseCase.contract!(name: 'Kotaro', age: 7)
      use_case = DummyUseCase.new(contract)
      result = use_case.build_parameter!
      expect(result).to be_a(Dry::Monads::Success)
      expect(result.value!).to respond_to(:name)
      expect(result.value!.name).to eq('Kotaro')
    end

    it 'mengembalikan Failure(hash error) ketika tidak valid' do
      contract = DummyUseCase.contract!(age: 'tujuh')
      result = DummyUseCase.new(contract).build_parameter!
      expect(result).to be_a(Dry::Monads::Failure)
      expect(result.failure).to be_a(Hash)
      expect(result.failure.keys).to include(:name) # name wajib
    end
  end

  describe '#result' do
    it 'menggunakan Do-notation dengan mulus' do
      contract = DummyUseCase.contract!(name: 'Alam')
      res = DummyUseCase.new(contract).result
      expect(res).to be_success
      expect(res.value!.name).to eq('Alam')
    end
  end
end
