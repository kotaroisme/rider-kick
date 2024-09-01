# typed: ignore
# frozen_string_literal: true

require 'dry-types'

module Types
  include Dry.Types()
  # File = Types.Instance(::File) | Types.Instance(ActionDispatch::Http::UploadedFile)
  # public_constant :File
end
