# frozen_string_literal: true

require 'rails/generators'
require 'active_support/inflector'
require 'active_support/core_ext/object/blank'
require 'active_support/core_ext/enumerable'
require 'hashie'

module RiderKick
  class Structure < Rails::Generators::Base
    source_root File.expand_path('templates', __dir__)

    argument :arg_model_name, type: :string, default: '', banner: 'Models::Name'
    argument :arg_settings, type: :hash, default: {}, banner: 'route_scope:dashboard actor:user uploaders:assets,images,picture,document'
    class_option :engine, type: :string, default: nil, desc: 'Specify engine name (e.g., Core, Admin)'

    def generate_use_case
      configure_engine
      validation!
      setup_variables
      generate_files(@scope_path)
    end

    private

    def configure_engine
      if options[:engine].present?
        RiderKick.configuration.engine_name = options[:engine]
        say "Using engine: #{RiderKick.configuration.engine_name}", :green
      else
        # Pastikan engine_name nil jika tidak di-specify, sehingga menggunakan main app
        RiderKick.configuration.engine_name = nil
        say 'Using main app (no engine specified)', :blue
      end
    end

    def validation!
      unless Dir.exist?(RiderKick.configuration.domains_path)
        say 'Error must create clean arch structure first!'
        raise Thor::Error, 'run: bin/rails generate rider_kick:clean_arch --setup'
      end
    end

    def setup_variables
      @variable_subject   = arg_model_name.split('::').last.underscore.downcase
      @model_class        = arg_model_name.camelize.constantize
      @subject_class      = arg_model_name.split('::').last
      @scope_path         = @subject_class.pluralize.underscore.downcase
      @scope_class        = @scope_path.camelize
      @fields             = contract_fields
      @uploaders          = uploaders # Ini array string dari argumen
      @actor              = arg_settings['actor'].downcase

      @resource_owner_id  = arg_settings['resource_owner_id'].to_s.presence
      @columns            = columns_meta

      @type_mapping = RiderKick::TYPE_MAPPING
      @entity_type_mapping = RiderKick::ENTITY_TYPE_MAPPING

      @columns_meta_hash = @columns.index_by { |c| c[:name] }

      @contract_lines_for_create = @fields.map do |field_name|
        column_meta = @columns_meta_hash[field_name]
        next nil if column_meta.nil?

        predicate = column_meta[:null] ? 'optional' : 'required'
        db_type = get_column_type(field_name).to_s
        validation_type = @type_mapping[db_type]

        if db_type == 'upload'
          validation_type = 'Types::File'
        elsif validation_type.nil?
          validation_type = ':string'
        end

        if predicate == 'required'
          "\"required(:#{field_name}).filled(#{validation_type})\""
        else
          "\"optional(:#{field_name}).maybe(#{validation_type})\""
        end
      end.compact

      @contract_lines_for_update = @fields.map do |field_name|
        column_meta = @columns_meta_hash[field_name]
        next nil if column_meta.nil?

        db_type = get_column_type(field_name).to_s
        validation_type = @type_mapping[db_type]

        if db_type == 'upload'
          validation_type = 'Types::File'
        elsif validation_type.nil?
          validation_type = ':string'
        end

        "\"optional(:#{field_name}).maybe(#{validation_type})\""
      end.compact

      search_able_fields = arg_settings['search_able'].to_s.split(',').map(&:strip).reject(&:blank?)

      @repository_list_filters = search_able_fields.map do |field|
        "{ field: '#{field}', type: 'search' }"
      end

      @contract_lines_for_list = @repository_list_filters.map do |filter_hash|
        field_name = filter_hash.match(/field: '([^']+)'/)[1]
        "\"optional(:#{field_name}).maybe(:string)\""
      end

      @entity_db_fields = @fields

      # 1. Tentukan definisi uploader yang kaya (array of hashes)
      #    @uploaders di sini masih array string dari argumen
      @entity_uploader_definitions = @uploaders.map do |uploader_name|
        type = is_singular?(uploader_name) ? 'single' : 'multiple'
        # PERBAIKAN: Ini harus menjadi Hash, BUKAN String
        { name: uploader_name, type: type }
      end
    end

    def columns_meta
      @model_class.columns.map do |c|
        {
          name:      c.name.to_s,
          type:      c.type,
          sql_type:  (c.respond_to?(:sql_type) ? c.sql_type : nil),
          null:      (c.respond_to?(:null) ? c.null : nil),
          default:   (c.respond_to?(:default) ? c.default : nil),
          precision: (c.respond_to?(:precision) ? c.precision : nil),
          scale:     (c.respond_to?(:scale) ? c.scale : nil),
          limit:     (c.respond_to?(:limit) ? c.limit : nil)
        }
      end
    end

    def fkeys_meta   = []

    def indexes_meta = []

    def enums_meta   = {}

    def contract_lines_for_create
      @contract_lines_for_create || []
    end

    def contract_lines_for_update
      @contract_lines_for_update || []
    end

    def contract_lines_for_list
      @contract_lines_for_list || []
    end

    def repository_list_filters
      @repository_list_filters || []
    end

    def entity_db_fields
      @entity_db_fields || []
    end

    def entity_uploader_definitions
      @entity_uploader_definitions || []
    end

    def is_singular?(str)
      str.singularize == str
    end

    def generate_files(action)
      template 'db/structures/example.yaml.tt', File.join("db/structures/#{action}_structure.yaml")
    end

    def contract_fields
      # Metode ini sekarang hanya digunakan oleh setup_variables untuk @fields
      @model_class.columns.reject { |column|
        (uploaders + ['id', 'created_at', 'updated_at', 'type']).include?(column.name.to_s)
      }.map(&:name).map(&:to_s)
    end

    def get_column_type(field)
      # uploaders di sini masih array string
      uploaders.include?(field) ?
        'upload' : @model_class.columns_hash[field].type
    end

    def uploaders
      # Ini adalah array string mentah dari argumen
      return [] unless arg_settings['uploaders'].present?
      arg_settings['uploaders'].split(',').map(&:strip)
    end
  end
end
