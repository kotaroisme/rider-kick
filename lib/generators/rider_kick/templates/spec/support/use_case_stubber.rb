# frozen_string_literal: true

module UseCaseStubber
  def stub_use_case(use_case, expected_output, response: :success)
    mock_fetcher = instance_double(use_case)
    allow(use_case).to(receive(:contract!).and_return(true))
    allow(use_case).to(receive(:new).and_return(mock_fetcher))
    if response.to_s.eql?('success')
      allow(mock_fetcher).to receive(:result).and_return(Dry::Monads::Success(expected_output))
    else
      allow(mock_fetcher).to receive(:result).and_return(Dry::Monads::Failure(expected_output))
    end
  end
end
