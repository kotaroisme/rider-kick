# frozen_string_literal: true

RSpec.describe RiderKick::Entities::FailureDetails do
  it 'from_array menggabungkan pesan secara dinamis' do
    fd = described_class.from_array(%w[alpha beta gamma])
    expect(fd.message).to eq('alpha, beta, gamma')
    expect(fd.type).to eq(:error)
    expect(fd.other_properties).to eq({})
  end

  it 'from_string membungkus string menjadi FailureDetails' do
    fd = described_class.from_string('oops')
    expect(fd.message).to eq('oops')
    expect(fd.type).to eq(:error)
  end

  it 'bisa dibuat dengan default type error' do
    fd = described_class.new(message: 'X') # sengaja tanpa :type
    expect(fd.type).to eq(:error)
    expect(fd.other_properties).to eq({})
  end
end
