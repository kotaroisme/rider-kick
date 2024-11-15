require 'yaml'
module RiderKick
  class ScaffoldGenerator < Rails::Generators::Base
    source_root File.expand_path('templates', __dir__)

    argument :arg_structure, type: :string, default: '', banner: ''

    def generate_use_case
      validation!
      setup_variables

      generate_files('create')
      generate_files('update')
      generate_files('list')
      generate_files('destroy')
      generate_files('fetch', '_by_id')

      copy_builder_and_entity_files
    end

    private

    def validation!
      unless File.exist?('config/initializers/rider_kick.rb')
        say 'Error must create init configuration for rider_kick!'
        raise Thor::Error, 'run: bin/rails generate rider_kick:init'
      end
    end

    def setup_variables
      config     = YAML.load_file("db/structures/#{arg_structure}_structure.yaml")
      @structure = Hashie::Mash.new(config)

      # Mengambil detail konfigurasi
      model_name    = @structure.model
      resource_name = @structure.resource_name.singularize.underscore.downcase
      entity        = @structure.entity || {}

      @actor                = @structure.actor
      @uploaders            = @structure.uploaders || []
      @search_able          = @structure.search_able || []
      @services             = @structure.services || {}
      @contract_list        = @services.action_list.contract || []
      @contract_fetch_by_id = @services.action_fetch_by_id.contract || []
      @contract_create      = @services.action_create.contract || []
      @contract_update      = @services.action_update.contract || []
      @contract_destroy     = @services.action_destroy.contract || []
      @skipped_fields       = entity.skipped_fields || []
      @custom_fields        = entity.custom_fields || []

      @variable_subject = model_name.split('::').last.underscore.downcase
      @scope_path       = resource_name.pluralize.underscore.downcase
      @model_class      = model_name.camelize.constantize
      @subject_class    = resource_name.camelize
      @fields           = contract_fields

      @type_mapping = {
        'uuid'     => ':string',
        'string'   => ':string',
        'text'     => ':string',
        'integer'  => ':integer',
        'boolean'  => ':bool',
        'float'    => ':float',
        'decimal'  => ':float',
        'date'     => ':date',
        'upload'   => 'Types::File',
        'datetime' => ':string'
      }
      @entity_type_mapping = {
        'uuid'     => 'Types::Strict::String',
        'string'   => 'Types::Strict::String',
        'text'     => 'Types::Strict::String',
        'integer'  => 'Types::Strict::Integer',
        'boolean'  => 'Types::Strict::Bool',
        'float'    => 'Types::Strict::Float',
        'decimal'  => 'Types::Strict::Decimal',
        'date'     => 'Types::Strict::Date',
        'datetime' => 'Types::Strict::Time'
      }
    end

    def generate_files(action, suffix = '')
      use_case_filename   = build_usecase_filename(action, suffix)
      repository_filename = build_repository_filename(action, suffix)

      @scope_class      = @scope_path.camelize
      @use_case_class   = use_case_filename.camelize
      @repository_class = repository_filename.camelize

      template "domains/core/use_cases/#{action + suffix}.rb.tt", File.join("#{root_path_app}/domains/core/use_cases/#{@scope_path}", "#{use_case_filename}.rb")
      template "domains/core/repositories/#{action + suffix}.rb.tt", File.join("#{root_path_app}/domains/core/repositories/#{@scope_path}", "#{repository_filename}.rb")
    end

    def copy_builder_and_entity_files
      template 'domains/core/builders/builder.rb.tt', File.join("#{root_path_app}/domains/core/builders", "#{@variable_subject}.rb")
      template 'domains/core/entities/entity.rb.tt', File.join("#{root_path_app}/domains/core/entities", "#{@variable_subject}.rb")
    end

    def contract_fields
      skip_contract_fields = @skipped_fields.map(&:strip).uniq
      if RiderKick.scope_owner_column.present?
        skip_contract_fields << RiderKick.scope_owner_column.to_s
      end
      @model_class.columns.reject { |column| skip_contract_fields.include?(column.name.to_s) }.map(&:name).map(&:to_s)
    end

    def get_column_type(field)
      @uploaders.include?(field) ? 'upload' : @model_class.columns_hash[field.to_s].type
    end

    def root_path_app
      'app'
    end

    def build_usecase_filename(action, suffix = '')
      "#{@actor}_#{action}_#{@variable_subject}#{suffix}"
    end

    def build_repository_filename(action, suffix = '')
      "#{action}_#{@variable_subject}#{suffix}"
    end
  end
end
