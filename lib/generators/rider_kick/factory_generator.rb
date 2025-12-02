# frozen_string_literal: true

require 'rails/generators'
require 'active_support/inflector'
require 'faker'
require_relative 'base_generator'
require_relative '../../rider-kick'

module RiderKick
  class FactoryGenerator < BaseGenerator
    source_root File.expand_path('templates', __dir__)

    argument :arg_model_name, type: :string, banner: 'Models::Article'
    argument :arg_scope, type: :hash, default: {}, banner: 'scope:core'
    class_option :engine, type: :string, default: nil, desc: 'Specify engine name (e.g., Core, Admin)'
    class_option :static, type: :boolean, default: false, desc: 'Generate static values instead of Faker calls'

    def generate_factory
      configure_engine
      setup_variables
      generate_factory_file
    end

    private

    def setup_variables
      @model_name = arg_model_name
      validate_model_exists!(@model_name)
      @model_class = @model_name.constantize
      @variable_subject = @model_name.split('::').last.underscore.downcase
      @factory_name = @variable_subject
      @scope_path = arg_scope.fetch('scope', '').to_s.downcase

      # Get all columns excluding those we want to skip
      @attributes = @model_class.columns.reject do |column|
        skip_column?(column.name)
      end
    rescue ModelNotFoundError => e
      say "Error: #{e.message}", :red
      raise
    end

    def skip_column?(column_name)
      # Skip id, timestamps, and all foreign key columns (ending with _id)
      ['id', 'created_at', 'updated_at', 'type'].include?(column_name) ||
        column_name.end_with?('_id')
    end

    def generate_factory_file
      factory_dir = if @scope_path.present?
        File.join('spec', 'factories', @scope_path)
      else
        File.join('spec', 'factories')
      end

      empty_directory factory_dir unless Dir.exist?(factory_dir)

      factory_file_path = File.join(factory_dir, "#{@factory_name}.rb")
      template 'spec/factories/factory.rb.tt', factory_file_path

      say "Factory created: #{factory_file_path}", :green
    end

    def generate_faker_value(column)
      faker_expression = get_faker_expression(column)

      # Time-based columns always use Time.zone.now, even with --static
      if is_time_column?(column)
        faker_expression
      elsif options[:static]
        evaluate_faker_expression(faker_expression)
      else
        faker_expression
      end
    end

    def is_time_column?(column)
      ['datetime', 'timestamp', 'time'].include?(column.type.to_s)
    end

    def get_faker_expression(column)
      case column.type.to_s
      when 'string'
        if column.name.include?('email')
          'Faker::Internet.email'
        elsif column.name.include?('name')
          'Faker::Name.name'
        elsif column.name.include?('phone')
          'Faker::PhoneNumber.phone_number'
        elsif column.name.include?('address')
          'Faker::Address.full_address'
        elsif column.name.include?('city')
          'Faker::Address.city'
        elsif column.name.include?('country')
          'Faker::Address.country'
        elsif column.name.include?('url') || column.name.include?('website')
          'Faker::Internet.url'
        elsif column.name.include?('title')
          'Faker::Lorem.sentence(word_count: 3)'
        elsif column.name.include?('code')
          'Faker::Alphanumeric.alphanumeric(number: 10)'
        else
          'Faker::Lorem.word'
        end
      when 'text'
        if column.name.include?('description') || column.name.include?('content') || column.name.include?('body')
          'Faker::Lorem.paragraph(sentence_count: 3)'
        else
          'Faker::Lorem.sentence'
        end
      when 'integer'
        if column.name.include?('count') || column.name.include?('quantity')
          'Faker::Number.between(from: 1, to: 100)'
        elsif column.name.include?('age')
          'Faker::Number.between(from: 18, to: 80)'
        elsif column.name.include?('price') || column.name.include?('amount')
          'Faker::Number.between(from: 1000, to: 1000000)'
        else
          'Faker::Number.number(digits: 5)'
        end
      when 'bigint'
        'Faker::Number.number(digits: 10)'
      when 'float'
        'Faker::Number.decimal(l_digits: 2, r_digits: 2)'
      when 'decimal'
        if column.name.include?('price') || column.name.include?('amount')
          'Faker::Commerce.price'
        else
          'Faker::Number.decimal(l_digits: 4, r_digits: 2)'
        end
      when 'boolean'
        '[true, false].sample'
      when 'date'
        'Faker::Date.between(from: 1.year.ago, to: Date.today)'
      when 'datetime', 'timestamp', 'time'
        'Time.zone.now'
      when 'uuid'
        'SecureRandom.uuid'
      when 'json', 'jsonb'
        '{ key: Faker::Lorem.word, value: Faker::Lorem.sentence }'
      when 'inet'
        'Faker::Internet.ip_v4_address'
      when 'cidr'
        'Faker::Internet.ip_v4_cidr'
      when 'macaddr'
        'Faker::Internet.mac_address'
      else
        # Default fallback
        'Faker::Lorem.word'
      end
    end

    def evaluate_faker_expression(expression)
      # Safely evaluate the Faker expression using whitelist mapping
      result = safe_evaluate_faker_expression(expression)
      format_static_value(result)
    rescue => e
      say "Warning: Could not evaluate '#{expression}': #{e.message}", :yellow
      expression # Fallback to original expression if evaluation fails
    end

    def safe_evaluate_faker_expression(expression)
      # Check custom FakerMapping registry first
      custom_mapping = RiderKick::FakerMapping.get(expression)
      return custom_mapping.call if custom_mapping

      # Whitelist mapping for safe Faker expression evaluation
      faker_methods = {
        'Faker::Internet.email'                                    => -> { Faker::Internet.email },
        'Faker::Name.name'                                         => -> { Faker::Name.name },
        'Faker::PhoneNumber.phone_number'                          => -> { Faker::PhoneNumber.phone_number },
        'Faker::Address.full_address'                              => -> { Faker::Address.full_address },
        'Faker::Address.city'                                      => -> { Faker::Address.city },
        'Faker::Address.country'                                   => -> { Faker::Address.country },
        'Faker::Internet.url'                                      => -> { Faker::Internet.url },
        'Faker::Lorem.sentence(word_count: 3)'                     => -> { Faker::Lorem.sentence(word_count: 3) },
        'Faker::Alphanumeric.alphanumeric(number: 10)'             => -> { Faker::Alphanumeric.alphanumeric(number: 10) },
        'Faker::Lorem.word'                                        => -> { Faker::Lorem.word },
        'Faker::Lorem.paragraph(sentence_count: 3)'                => -> { Faker::Lorem.paragraph(sentence_count: 3) },
        'Faker::Lorem.sentence'                                    => -> { Faker::Lorem.sentence },
        'Faker::Number.between(from: 1, to: 100)'                  => -> { Faker::Number.between(from: 1, to: 100) },
        'Faker::Number.between(from: 18, to: 80)'                  => -> { Faker::Number.between(from: 18, to: 80) },
        'Faker::Number.between(from: 1000, to: 1000000)'           => -> { Faker::Number.between(from: 1000, to: 1_000_000) },
        'Faker::Number.number(digits: 5)'                          => -> { Faker::Number.number(digits: 5) },
        'Faker::Number.number(digits: 10)'                         => -> { Faker::Number.number(digits: 10) },
        'Faker::Number.decimal(l_digits: 2, r_digits: 2)'          => -> { Faker::Number.decimal(l_digits: 2, r_digits: 2) },
        'Faker::Commerce.price'                                    => -> { Faker::Commerce.price },
        'Faker::Number.decimal(l_digits: 4, r_digits: 2)'          => -> { Faker::Number.decimal(l_digits: 4, r_digits: 2) },
        '[true, false].sample'                                     => -> { [true, false].sample },
        'Faker::Date.between(from: 1.year.ago, to: Date.today)'    => -> { Faker::Date.between(from: 1.year.ago, to: Date.today) },
        'Time.zone.now'                                            => -> { Time.zone.now },
        'SecureRandom.uuid'                                        => -> { SecureRandom.uuid },
        '{ key: Faker::Lorem.word, value: Faker::Lorem.sentence }' => -> { { key: Faker::Lorem.word, value: Faker::Lorem.sentence } },
        'Faker::Internet.ip_v4_address'                            => -> { Faker::Internet.ip_v4_address },
        'Faker::Internet.ip_v4_cidr'                               => -> { Faker::Internet.ip_v4_cidr },
        'Faker::Internet.mac_address'                              => -> { Faker::Internet.mac_address }
      }

      # Check if expression is in whitelist
      if faker_methods.key?(expression)
        faker_methods[expression].call
      else
        # Fallback: try to parse simple expressions
        # Handle expressions with parameters (basic parsing)
        case expression
        when /^Faker::(\w+)\.(\w+)$/
          # Simple Faker::Module.method format
          module_name = Regexp.last_match(1)
          method_name = Regexp.last_match(2)
          faker_module = Faker.const_get(module_name)
          faker_module.public_send(method_name)
        else
          # If not in whitelist and can't parse, raise error
          raise ArgumentError, "Expression '#{expression}' is not in the safe whitelist"
        end
      end
    end

    def format_static_value(value)
      case value
      when String
        "'#{value.gsub("'", "\\\\'")}'"
      when Numeric
        value.to_s
      when TrueClass, FalseClass
        value.to_s
      when Date
        "'#{value}'"
      when Time, DateTime
        "'#{value.strftime('%Y-%m-%d %H:%M:%S')}'"
      when Hash
        value.inspect
      else
        value.inspect
      end
    end
  end
end
