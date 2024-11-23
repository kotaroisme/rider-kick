module RiderKick
  class Structure < Rails::Generators::Base
    source_root File.expand_path('templates', __dir__)

    argument :arg_model_name, type: :string, default: '', banner: 'Models::Name'
    argument :arg_settings, type: :hash, default: '', banner: 'route_scope:dashboard actor:user uploaders:assets,images,picture,document'

    def generate_use_case
      validation!
      setup_variables
      generate_files(@scope_path)
    end

    private

    def validation!
      unless Dir.exist?('app/domains')
        say 'Error must create clean arch structure first!'
        raise Thor::Error, 'run: bin/rails generate rider_kick:clean_arch --setup'
      end
    end

    def setup_variables
      @scope_owner_column = (SunSword.scope_owner_column.to_s rescue '')
      @variable_subject   = arg_model_name.split('::').last.underscore.downcase
      @model_class        = arg_model_name.camelize.constantize
      @subject_class      = arg_model_name.split('::').last
      @scope_path         = @subject_class.pluralize.underscore.downcase
      @scope_class        = @scope_path.camelize
      @fields             = contract_fields
      @uploaders          = uploaders
      @actor              = arg_settings['actor'].downcase

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

    def is_singular?(str)
      str.singularize == str
    end

    def generate_files(action)
      template 'db/structures/example.yaml.tt', File.join("db/structures/#{action}_structure.yaml")
    end

    def contract_fields
      @model_class.columns.reject { |column| (['id', 'created_at', 'updated_at', 'type'] + [@scope_owner_column.to_s]).include?(column.name.to_s) }.map(&:name).map(&:to_s)
    end

    def get_column_type(field)
      uploaders.include?(field) ? 'upload' : @model_class.columns_hash[field].type
    end

    def uploaders
      return [] unless arg_settings['uploaders'].present?
      arg_settings['uploaders'].split(',').map(&:strip)
    end
  end
end
