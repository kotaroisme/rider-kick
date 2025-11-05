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
    'datetime' => ':date_time'
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
    attr_reader :domains_path
    attr_accessor :entities_path, :adapters_path

    def initialize
      @domains_path  = 'app/domains'
      @entities_path = File.join(@domains_path, 'core/entities')
      @adapters_path = File.join(@domains_path, 'adapters')
    end

    def domains_path=(path)
      @domains_path = File.expand_path(path)
      @entities_path = File.join(@domains_path, 'core/entities')
      @adapters_path = File.join(@domains_path, 'adapters')
    end
  end

  def self.configuration
    @configuration ||= Configuration.new
  end

  def self.configure
    yield(configuration)
  end
end
