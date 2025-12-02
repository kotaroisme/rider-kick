# frozen_string_literal: true

require 'active_support/inflector'

module RiderKick
  DEFAULT_TYPE_MAPPING = {
    'uuid'     => ':string',
    'string'   => ':string',
    'text'     => ':string',
    'integer'  => ':integer',
    'boolean'  => ':bool',
    'float'    => ':float',
    'decimal'  => ':decimal',
    'date'     => ':date',
    'upload'   => 'Types::File',
    'datetime' => ':time'
  }.freeze
  public_constant :DEFAULT_TYPE_MAPPING

  DEFAULT_ENTITY_TYPE_MAPPING = {
    'uuid'     => 'Types::Strict::String',
    'string'   => 'Types::Strict::String',
    'text'     => 'Types::Strict::String',
    'integer'  => 'Types::Strict::Integer',
    'boolean'  => 'Types::Strict::Bool',
    'float'    => 'Types::Strict::Float',
    'decimal'  => 'Types::Strict::Decimal',
    'date'     => 'Types::Strict::Date',
    'datetime' => 'Types::Strict::Time'
  }.freeze
  public_constant :DEFAULT_ENTITY_TYPE_MAPPING
  # Backward compatibility constants
  TYPE_MAPPING = DEFAULT_TYPE_MAPPING
  ENTITY_TYPE_MAPPING = DEFAULT_ENTITY_TYPE_MAPPING
  public_constant :TYPE_MAPPING
  public_constant :ENTITY_TYPE_MAPPING

  # Faker mapping registry for factory generator customization
  class FakerMapping
    @mappings = {}

    class << self
      attr_reader :mappings

      def register(expression, &block)
        @mappings[expression] = block
      end

      def get(expression)
        @mappings[expression]
      end

      def clear
        @mappings = {}
      end
    end
  end

  class Configuration
    attr_reader :domains_path, :models_path, :engine_name, :domain_scope, :template_path
    attr_accessor :entities_path, :adapters_path

    def initialize
      @engine_name   = detect_engine_name
      @domain_scope  = ''
      @domains_path  = detect_domains_path
      @entities_path = File.join(@domains_path, 'entities')
      @adapters_path = File.join(@domains_path, 'adapters')
      @models_path   = detect_models_path
      @template_path = nil
      @type_mapping = DEFAULT_TYPE_MAPPING.dup
      @entity_type_mapping = DEFAULT_ENTITY_TYPE_MAPPING.dup
    end

    attr_reader :type_mapping

    attr_reader :entity_type_mapping

    def register_type_mapping(db_type, dry_type)
      @type_mapping[db_type.to_s] = dry_type.to_s
    end

    def register_entity_type_mapping(db_type, dry_type)
      @entity_type_mapping[db_type.to_s] = dry_type.to_s
    end

    def domains_path=(path)
      validate_path_format!(path, 'domains_path')
      @domains_path = File.expand_path(path)
      @entities_path = File.join(@domains_path, 'entities')
      @adapters_path = File.join(@domains_path, 'adapters')
    end

    def models_path=(path)
      validate_path_format!(path, 'models_path')
      @models_path = File.expand_path(path)
    end

    def template_path=(path)
      if path.nil? || path.to_s.strip.empty?
        @template_path = nil
      else
        validate_path_format!(path, 'template_path')
        @template_path = File.expand_path(path)
      end
    end

    def engine_name=(name)
      if name.nil? || name.to_s.strip.empty?
        @engine_name = nil
      else
        validate_engine_name_format!(name)
        @engine_name = name.to_s
      end
      @models_path = detect_models_path
      @domains_path = detect_domains_path
      @entities_path = File.join(@domains_path, 'entities')
      @adapters_path = File.join(@domains_path, 'adapters')
    end

    def domain_scope=(scope)
      if scope.nil? || scope.to_s.strip.empty?
        @domain_scope = ''
      else
        validate_domain_scope_format!(scope)
        @domain_scope = scope.to_s
      end
      @domains_path = detect_domains_path
      @entities_path = File.join(@domains_path, 'entities')
      @adapters_path = File.join(@domains_path, 'adapters')
    end

    private

    def validate_path_format!(path, attribute_name)
      path_str = path.to_s.strip
      return if path_str.empty?

      # Basic path validation - should not contain invalid characters
      if path_str.match?(/[<>:"|?*\x00-\x1f]/)
        raise RiderKick::ConfigurationError.new(
                "Invalid #{attribute_name} format: contains invalid characters",
                attribute: attribute_name,
                value:     path_str
        )
      end
    end

    def validate_engine_name_format!(name)
      name_str = name.to_s.strip
      return if name_str.empty?

      # Engine name can be CamelCase (e.g., 'Core', 'Admin') or underscore_case (e.g., 'order_engine')
      # Both formats are acceptable and will be converted as needed
      unless name_str.match?(/^[A-Z][a-zA-Z0-9]*$/) || name_str.match?(/^[a-z][a-z0-9_]*$/)
        raise RiderKick::ConfigurationError.new(
                "Invalid engine_name format: must be CamelCase (e.g., 'Core', 'Admin') or underscore_case (e.g., 'order_engine')",
                attribute:  'engine_name',
                value:      name_str,
                suggestion: "Use CamelCase format like 'Core' or 'Admin', or underscore_case like 'order_engine'"
        )
      end
    end

    def validate_domain_scope_format!(scope)
      scope_str = scope.to_s.strip
      return if scope_str.empty?

      # Domain scope should contain only alphanumeric, slash, underscore, hyphen
      unless scope_str.match?(/^[a-zA-Z0-9\/_-]+$/)
        raise RiderKick::ConfigurationError.new(
                'Invalid domain_scope format: must contain only alphanumeric characters, slashes, underscores, and hyphens',
                attribute:  'domain_scope',
                value:      scope_str,
                suggestion: "Use format like 'core/', 'admin/', 'api/v1/'"
        )
      end
    end

    def detect_engine_name
      # Detect engine dari struktur file system
      # Cek apakah ada lib/<name>/engine.rb
      return nil unless Dir.exist?('lib')

      engines = []
      Dir.glob('lib/*/engine.rb').each do |engine_file|
        engine_name = File.basename(File.dirname(engine_file))
        engines << engine_name.camelize if File.exist?(engine_file)
      end

      # Jika hanya ada satu engine, return itu
      return engines.first if engines.length == 1

      # Jika ada multiple engines, return nil (user harus specify via --engine option)
      # Atau cek dari gem name di gemspec (fallback)
      gemspec_files = Dir.glob('*.gemspec')
      unless gemspec_files.empty?
        gemspec_content = File.read(gemspec_files.first)
        if gemspec_content =~ /\.name\s*=\s*["']([^"']+)["']/
          gem_name = Regexp.last_match(1)
          # Extract engine name dari gem name (e.g., "my_app-core" -> "Core")
          engine_name = gem_name.split(/[-_]/).last.camelize
          return engine_name if Dir.exist?("lib/#{engine_name.underscore}") && engines.include?(engine_name)
        end
      end

      nil
    end

    def detect_models_path
      if @engine_name
        # Engine: engines/<engine_name>/app/models/<engine_name>/models
        File.join('engines', @engine_name.underscore, 'app/models', @engine_name.underscore, 'models')
      else
        # Main app: app/models/models
        'app/models/models'
      end
    end

    def detect_domains_path
      if @engine_name
        # Engine: engines/<engine_name>/app/domains/<domain_scope>
        File.join('engines', @engine_name.underscore, 'app/domains', @domain_scope)
      else
        # Main app: app/domains/<domain_scope>
        File.join('app/domains', @domain_scope)
      end
    end
  end

  def self.configuration
    @configuration ||= Configuration.new
  end

  def self.configure
    yield(configuration)
  end
end
