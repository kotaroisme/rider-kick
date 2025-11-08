# frozen_string_literal: true

# ClassStubber provides utilities for creating test doubles of ActiveRecord models
# and ActiveStorage attachments in a clean, hash-based way.
#
# Usage:
#   model = ClassStubber::Model.new(
#     'id' => '123',
#     'name' => 'Test Name',
#     'avatar' => ClassStubber::ActiveStorageAttachment.new_single('http://example.com/avatar.jpg')
#   )
module ClassStubber
  # Model stub that responds to hash keys as methods
  class Model
    def initialize(attributes = {})
      @attributes = attributes.transform_keys(&:to_s)
    end

    def method_missing(method_name, *args, &block)
      key = method_name.to_s
      if @attributes.key?(key)
        @attributes[key]
      else
        super
      end
    end

    def respond_to_missing?(method_name, include_private = false)
      @attributes.key?(method_name.to_s) || super
    end

    def [](key)
      @attributes[key.to_s]
    end

    def []=(key, value)
      @attributes[key.to_s] = value
    end

    def to_h
      @attributes
    end

    def attributes
      @attributes
    end
  end

  # ActiveStorage attachment stub for single file attachments
  class ActiveStorageAttachment
    # Creates a stub for a single file attachment (has_one_attached)
    #
    # @param url [String, nil] The URL of the attached file, or nil if not attached
    # @return [ActiveStorageAttachmentSingle] A stub that responds to attached? and url
    def self.new_single(url)
      ActiveStorageAttachmentSingle.new(url)
    end

    # Creates a stub for multiple file attachments (has_many_attached)
    #
    # @param urls [Array<String>] Array of URLs for attached files
    # @return [ActiveStorageAttachmentMultiple] A stub that responds to attached? and can be enumerated
    def self.new_multiple(urls = [])
      ActiveStorageAttachmentMultiple.new(urls)
    end
  end

  # Single file attachment stub
  class ActiveStorageAttachmentSingle
    attr_reader :url

    def initialize(url)
      @url = url
    end

    def attached?
      !@url.nil?
    end

    def blank?
      !attached?
    end

    def present?
      attached?
    end
  end

  # Multiple files attachment stub
  class ActiveStorageAttachmentMultiple
    include Enumerable

    attr_reader :urls

    def initialize(urls = [])
      @urls = urls.compact
      @attachments = @urls.map { |url| ActiveStorageAttachmentSingle.new(url) }
    end

    def attached?
      @urls.any?
    end

    def blank?
      !attached?
    end

    def present?
      attached?
    end

    def each(&block)
      @attachments.each(&block)
    end

    def map(&block)
      @attachments.map(&block)
    end

    def size
      @attachments.size
    end

    def count
      size
    end

    def length
      size
    end

    def empty?
      @attachments.empty?
    end

    def first
      @attachments.first
    end

    def last
      @attachments.last
    end

    def [](index)
      @attachments[index]
    end
  end
end
