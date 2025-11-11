# frozen_string_literal: true

# Configure Faker
Faker::Config.locale = 'en' # or 'id' for Indonesian

# Faker random seed for reproducible test data
Faker::Config.random = Random.new(42)

# Optional: Configure Faker to use unique values by default
# This prevents duplicate data in tests
# Faker::UniqueGenerator.clear # Call this in an after block if needed

# Common Faker helpers for use in factories
module FakerHelpers
  def self.random_phone
    Faker::PhoneNumber.phone_number
  end

  def self.random_address
    Faker::Address.full_address
  end

  def self.random_company
    Faker::Company.name
  end

  def self.random_sentence(word_count: 10)
    Faker::Lorem.sentence(word_count: word_count)
  end

  def self.random_paragraph(sentence_count: 3)
    Faker::Lorem.paragraph(sentence_count: sentence_count)
  end

  def self.random_url
    Faker::Internet.url
  end

  def self.random_image_url(width: 640, height: 480)
    Faker::LoremFlickr.image(size: "#{width}x#{height}")
  end

  def self.random_date(from: 1.year.ago, to: Date.today)
    Faker::Date.between(from: from, to: to)
  end

  def self.random_datetime(from: 1.year.ago, to: Time.current)
    Faker::Time.between(from: from, to: to)
  end
end

# Make FakerHelpers available in tests
RSpec.configure do |config|
  config.include FakerHelpers
end



