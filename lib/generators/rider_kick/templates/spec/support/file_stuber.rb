# frozen_string_literal: true

module FileStubber
  def fixture_file(path, mime_type = nil, binary = false)
    config = RSpec.configuration

    if config.respond_to?(:fixture_paths) && config.fixture_paths && !File.exist?(path)
      path = File.join(config.fixture_paths, path)
    end

    Rack::Test::UploadedFile.new(path, mime_type, binary)
  end
end
