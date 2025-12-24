# frozen_string_literal: true

require_relative 'base_generator'

module RiderKick
  class InitGenerator < BaseGenerator
    source_root File.expand_path('templates', __dir__)

    desc 'Generate RiderKick configuration initializer'

    def create_initializer
      template 'config/initializers/rider_kick.rb.tt', 'config/initializers/rider_kick.rb'
    end
  end
end
