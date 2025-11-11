# frozen_string_literal: true

# Configure FactoryBot
RSpec.configure do |config|
  # Include FactoryBot methods in RSpec
  config.include FactoryBot::Syntax::Methods

  # Lint factories before running tests (optional, comment out if too slow)
  # config.before(:suite) do
  #   FactoryBot.lint
  # end
end

# FactoryBot configuration
FactoryBot.define do
  # Global configuration for FactoryBot
  
  # Use sequences for unique values
  sequence :email do |n|
    "user#{n}@example.com"
  end
  
  sequence :uuid do
    SecureRandom.uuid
  end
  
  # Add more global sequences or traits here as needed
end



