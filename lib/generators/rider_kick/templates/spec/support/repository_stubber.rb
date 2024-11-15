# frozen_string_literal: true

module RepositoryStubber
  def stub_repository(repository:, expected_output:, response: :success, params: nil)
    monads      = response.to_s.eql?('success') ? Dry::Monads::Success(expected_output) : Dry::Monads::Failure(expected_output)
    expectation = allow(repository).to receive(:new)
    expectation.with(params) if params
    expectation.and_return(instance_double(repository, call: monads))
  end
end
