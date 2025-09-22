# frozen_string_literal: true

require 'rider_kick/matchers/use_case_result'
require 'dry/monads'

RSpec.describe RiderKick::Matchers::UseCaseResult do
  subject(:matcher) { described_class }

  it 'melempar error untuk Failure value yang tidak didukung' do
    weird = Object.new
    expect {
      matcher.call(Dry::Monads::Failure(weird)) { |m| m.failure { |_| :ok } }
    }.to raise_error(ArgumentError, /Unexpected failure value/)
  end

  it 'meneruskan Entities::FailureDetails apa adanya' do
    fd  = RiderKick::Entities::FailureDetails.new(message: 'boom')
    out = nil

    RiderKick::Matchers::UseCaseResult.call(Dry::Monads::Failure(fd)) do |m|
      m.success { |_| raise 'unexpected success' }        # <- tambahkan handler success
      m.failure { |v| out = v }
    end

    expect(out).to be_a(RiderKick::Entities::FailureDetails)
    expect(out.message).to eq('boom')
  end
end
