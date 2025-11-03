# frozen_string_literal: true

require 'yaml'
module RiderKick
  class ScaffoldGenerator < Rails::Generators::Base
    source_root File.expand_path('templates', __dir__)

    argument :arg_structure, type: :string, default: '', banner: ''
    argument :arg_scope, type: :hash, default: '', banner: 'scope:dashboard'

    def generate_use_case
      validation!
      setup_variables

      generate_files('create')
      generate_files('update')
      generate_files('list')
      generate_files('destroy')
      generate_files('fetch', '_by_id')

      set_uploader_in_model
      copy_builder_and_entity_files
    end

    private

    def validation!
      unless Dir.exist?('app/domains')
        say 'Error must create clean arch structure first!'
        raise Thor::Error, 'run: bin/rails generate rider_kick:clean_arch --setup'
      end
    end

    def setup_variables
      config     = YAML.load_file("db/structures/#{arg_structure}_structure.yaml")
      @structure = Hashie::Mash.new(config)

      # Mengambil detail konfigurasi
      model_name    = @structure.model
      @model_class  = model_name.camelize.constantize # Pindahkan ini ke atas

      resource_name = @structure.resource_name.singularize.underscore.downcase
      entity        = @structure.entity || {}

      @actor                = @structure.actor
      @resource_owner_id    = @structure.resource_owner_id
      @services             = @structure.domains || {}

      # Membaca kontrak dinamis (dari Peningkatan #1)
      @contract_list        = @services.action_list&.use_case&.contract || []
      @contract_fetch_by_id = @services.action_fetch_by_id&.use_case&.contract || []
      @contract_create      = @services.action_create&.use_case&.contract || []
      @contract_update      = @services.action_update&.use_case&.contract || []
      @contract_destroy     = @services.action_destroy&.use_case&.contract || []

      # Membaca DSL filter repositori baru (Peningkatan #2)
      @repository_list_filters = @services.action_list&.repository&.filters || []

      # --- AWAL BLOK MODIFIKASI: PERBAIKAN (PENINGKATAN #3) ---

      # Membaca definisi uploader baru (array of hashes)
      @uploaders = (@structure.uploaders || []).map { |up| Hashie::Mash.new(up) }

      # Membaca atribut DB eksplisit (array string)
      @entity_db_fields = entity.db_attributes || []

      # --- AKHIR BLOK MODIFIKASI ---

      @variable_subject = model_name.split('::').last.underscore.downcase
      @scope_path       = resource_name.pluralize.underscore.downcase
      @scope_class      = @scope_path.camelize
      @scope_subject    = @scope_path.singularize
      @subject_class    = @variable_subject.camelize

      @fields           = contract_fields

      @route_scope_path = arg_scope['scope'].to_s.downcase rescue ''
      @route_scope_class = @route_scope_path.camelize rescue ''

      # --- AWAL BLOK MODIFIKASI: (PERBAIKAN KEGAGALAN #1) ---
      # Tambahkan hash metadata kolom, sama seperti di structure_generator
      @columns_meta      = columns_meta
      @columns_meta_hash = @columns_meta.index_by { |c| c[:name] }
      # --- AKHIR BLOK MODIFIKASI ---

      @type_mapping        = {
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

    def set_uploader_in_model
      @uploaders.each do |uploader|
        method_strategy = uploader.type == 'single' ? 'has_one_attached' : 'has_many_attached'
        uploader_name = uploader.name
        inject_into_file File.join("#{root_path_app}/models", @model_class.to_s.split('::').first.downcase.to_s, "#{@variable_subject}.rb"), "  #{method_strategy} :#{uploader_name}, dependent: :purge\n", after: "class #{@model_class} < ApplicationRecord\n" rescue nil
      end
    end

    def generate_files(action, suffix = '')
      use_case_filename   = build_usecase_filename(action, suffix)
      repository_filename = build_repository_filename(action, suffix)

      @use_case_class   = use_case_filename.camelize
      @repository_class = repository_filename.camelize

      template "domains/core/use_cases/#{action + suffix}.rb.tt", File.join("#{root_path_app}/domains/core/use_cases/", @route_scope_path.to_s, @scope_path.to_s, "#{use_case_filename}.rb")
      template "domains/core/repositories/#{action + suffix}.rb.tt", File.join("#{root_path_app}/domains/core/repositories/#{@scope_path}", "#{repository_filename}.rb")
    end

    def copy_builder_and_entity_files
      template 'domains/core/builders/builder.rb.tt', File.join("#{root_path_app}/domains/core/builders", "#{@variable_subject}.rb")
      template 'domains/core/entities/entity.rb.tt', File.join("#{root_path_app}/domains/core/entities", "#{@variable_subject}.rb")
    end

    def contract_fields
      @model_class.columns.map(&:name).map(&:to_s)
    end

    # --- AWAL BLOK MODIFIKASI: (PERBAIKAN KEGAGALAN #1) ---
    # Menambahkan helper-helper ini dari structure_generator
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

    def get_column_meta(field)
      @columns_meta_hash[field.to_s] || {}
    end
    # --- AKHIR BLOK MODIFIKASI ---

    def get_column_type(field)
      is_uploader = @uploaders.any? { |up| up.name == field.to_s }
      is_uploader ? 'upload' : @model_class.columns_hash[field.to_s].type
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
