# frozen_string_literal: true

module RiderKick
  # Base error class for all generator errors
  class GeneratorError < StandardError
    attr_reader :context

    def initialize(message, context = {})
      super(message)
      @context = context
    end

    def to_s
      if @context.any?
        context_str = @context.map { |k, v| "#{k}: #{v}" }.join(', ')
        "#{super} (#{context_str})"
      else
        super
      end
    end
  end

  # Error raised when validation fails
  class ValidationError < GeneratorError
  end

  # Error raised when configuration is invalid
  class ConfigurationError < GeneratorError
  end

  # Error raised when a model is not found
  class ModelNotFoundError < GeneratorError
  end

  # Error raised when a file is not found
  class FileNotFoundError < GeneratorError
  end

  # Error raised when YAML format is invalid
  class YamlFormatError < GeneratorError
  end
end

