# frozen_string_literal: true

require 'active_support/inflector'

module RiderKick
  TYPE_MAPPING = {
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
  public_constant :TYPE_MAPPING

  ENTITY_TYPE_MAPPING = {
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
  public_constant :ENTITY_TYPE_MAPPING

  class Configuration
    attr_reader :domains_path, :models_path, :engine_name, :domain_scope
    attr_accessor :entities_path, :adapters_path

    def initialize
      @engine_name   = detect_engine_name
      @domain_scope  = 'core/'
      @domains_path  = detect_domains_path
      @entities_path = File.join(@domains_path, 'entities')
      @adapters_path = File.join(@domains_path, 'adapters')
      @models_path   = detect_models_path
    end

    def domains_path=(path)
      @domains_path = File.expand_path(path)
      @entities_path = File.join(@domains_path, 'entities')
      @adapters_path = File.join(@domains_path, 'adapters')
    end

    def models_path=(path)
      @models_path = File.expand_path(path)
    end

    def engine_name=(name)
      @engine_name = name.nil? || name.to_s.strip.empty? ? nil : name.to_s
      @models_path = detect_models_path
      @domains_path = detect_domains_path
      @entities_path = File.join(@domains_path, 'entities')
      @adapters_path = File.join(@domains_path, 'adapters')
    end

    def domain_scope=(scope)
      @domain_scope = scope.nil? || scope.to_s.strip.empty? ? 'core/' : scope.to_s
      @domains_path = detect_domains_path
      @entities_path = File.join(@domains_path, 'entities')
      @adapters_path = File.join(@domains_path, 'adapters')
    end

    private

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
        # Engine: app/models/<engine_name>
        File.join('app/models', @engine_name.underscore)
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
