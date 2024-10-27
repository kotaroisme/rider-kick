module RiderKick
  class ScaffoldGenerator < Rails::Generators::Base
    source_root File.expand_path('templates', __dir__)

    argument :arg_model_name, type: :string, default: '', banner: 'Models::Name'
    argument :arg_settings, type: :hash, default: '', banner: 'actor:user uploader_filed:assets,images,picture,document skip_contract:organization_id'

    def generate_use_case
      setup_variables

      generate_files('create')
      generate_files('update')
      generate_files('list')
      generate_files('destroy')
      generate_files('fetch', '_by_id')

      copy_builder_and_entity_files
    end

    private

    def setup_variables
      @variable_subject = arg_model_name.split('::').last.underscore.downcase
      @model_class      = arg_model_name.camelize.constantize
      @subject_class    = arg_model_name.split('::').last
      @scope_path       = @subject_class.pluralize.underscore.downcase
      @fields           = contract_fields
      @uploaders        = uploaders
      setup_mappings
    end

    def setup_mappings
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
      skip_contract_fields = arg_settings['skip_contract'].split(',').map(&:strip)
      @model_class.columns.reject { |column| (%w[id created_at updated_at type] + skip_contract_fields).include?(column.name.to_s) }.map(&:name).map(&:to_s)
    end

    def get_column_type(field)
      uploaders.include?(field) ? 'upload' : @model_class.columns_hash[field].type
    end

    def uploaders
      return [] unless arg_settings['uploader_filed'].present?
      arg_settings['uploader_filed'].split(',').map(&:strip)
    end

    def root_path_app
      'app'
    end

    def build_usecase_filename(action, suffix = '')
      "#{arg_settings['actor'].downcase}_#{action}_#{@variable_subject}#{suffix}"
    end

    def build_repository_filename(action, suffix = '')
      "#{action}_#{@variable_subject}#{suffix}"
    end
  end
end
