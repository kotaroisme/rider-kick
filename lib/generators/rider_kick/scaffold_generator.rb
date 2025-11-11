# frozen_string_literal: true

require 'rails/generators'
require 'active_support/inflector'
require 'active_support/core_ext/object/blank'
require 'active_support/core_ext/enumerable'
require 'hashie'
require 'yaml'
require_relative '../../rider-kick'

module RiderKick
  class ScaffoldGenerator < Rails::Generators::Base
    source_root File.expand_path('templates', __dir__)

    argument :arg_structure, type: :string, default: '', banner: ''
    argument :arg_scope, type: :hash, default: {}, banner: 'scope:dashboard'
    class_option :engine, type: :string, default: nil, desc: 'Specify engine name (e.g., Core, Admin)'
    class_option :domain, type: :string, default: 'core/', desc: 'Specify domain scope (e.g., core/, admin/, api/v1/)'

    def generate_use_case
      configure_engine
      validation!
      setup_variables
      validate_repository_filters!   # ← validate filter fields exist (after setup_variables)
      validate_entity_fields!        # ← validate entity db_attributes exist (after setup_variables)

      generate_files('create')
      generate_files('update')
      generate_files('list')
      generate_files('destroy')
      generate_files('fetch', '_by_id')

      set_uploader_in_model
      copy_builder_and_entity_files
      generate_spec_files
    end

    private

    def domain_class_name
      # Convert domain scope to class name
      # "core/" -> "Core", "admin/" -> "Admin", "api/v1/" -> "Api::V1"
      scope = RiderKick.configuration.domain_scope.chomp('/')
      scope.split('/').map(&:camelize).join('::')
    end

    def configure_engine
      if options[:engine].present?
        RiderKick.configuration.engine_name = options[:engine]
        RiderKick.configuration.domain_scope = options[:domain] || 'core/'
        say "Using engine: #{RiderKick.configuration.engine_name}", :green
        say "Using domain scope: #{RiderKick.configuration.domain_scope}", :green
      elsif options[:domain].present?
        # Jika hanya --domain yang dispecify, gunakan konfigurasi existing
        RiderKick.configuration.domain_scope = options[:domain]
        say "Using domain scope: #{RiderKick.configuration.domain_scope}", :blue
      else
        # Jika tidak ada options, pertahankan konfigurasi existing
        # Hanya tampilkan pesan jika belum pernah di-set
        unless @engine_configured
          if RiderKick.configuration.engine_name
            say "Using engine: #{RiderKick.configuration.engine_name}", :green
            say "Using domain scope: #{RiderKick.configuration.domain_scope}", :green
          else
            say 'Using main app (no engine specified)', :blue
            say "Using domain scope: #{RiderKick.configuration.domain_scope}", :blue
          end
          @engine_configured = true
        end
      end
    end

    def validation!
      unless Dir.exist?(RiderKick.configuration.domains_path)
        say 'Error must create clean arch structure first!'
        raise Thor::Error, 'run: bin/rails generate rider_kick:clean_arch --setup'
      end
    end

    def validate_repository_filters!
      return if @repository_list_filters.empty?

      @repository_list_filters.each do |filter_hash|
        # Filter hash format: "{ field: 'name', type: 'search' }"
        # Kita perlu extract field name dari string ini
        match = filter_hash.match(/field: '([^']+)'/)
        next unless match

        field_name = match[1]

        unless @model_class.column_names.include?(field_name)
          raise Thor::Error, <<~ERROR
            Repository filter error di '#{arg_structure}_structure.yaml':
            Field '#{field_name}' tidak ditemukan di model #{@model_class}.

            Available columns: #{@model_class.column_names.join(', ')}
          ERROR
        end
      end
    end

    def validate_entity_fields!
      return if @entity_db_fields.empty?

      missing_fields = @entity_db_fields - @model_class.column_names

      if missing_fields.any?
        raise Thor::Error, <<~ERROR
          Entity configuration error di '#{arg_structure}_structure.yaml':
          Field(s) tidak ditemukan di model #{@model_class}: #{missing_fields.join(', ')}

          Available columns: #{@model_class.column_names.join(', ')}

          Fix: Update section 'entity.db_attributes' di YAML file.
        ERROR
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
      @resource_owner       = @structure.resource_owner
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
      @entity_db_fields = entity.respond_to?(:db_attributes) ? entity.db_attributes || [] : []

      # --- AKHIR BLOK MODIFIKASI ---

      @variable_subject = model_name.split('::').last.underscore.downcase
      @scope_path       = resource_name.pluralize.underscore.downcase
      @scope_class      = @scope_path.camelize
      @scope_subject    = @scope_path.singularize
      @subject_class    = @variable_subject.camelize
      @search_able      = @structure.search_able

      @fields           = contract_fields

      @route_scope_path = arg_scope.fetch('scope', '').to_s.downcase
      @route_scope_class = @route_scope_path.camelize

      # --- AWAL BLOK MODIFIKASI: (PERBAIKAN KEGAGALAN #1) ---
      # Tambahkan hash metadata kolom, sama seperti di structure_generator
      @columns_meta      = columns_meta
      @columns_meta_hash = @columns_meta.index_by { |c| c[:name] }
      # --- AKHIR BLOK MODIFIKASI ---

      @type_mapping        = RiderKick::TYPE_MAPPING
      @entity_type_mapping = RiderKick::ENTITY_TYPE_MAPPING
    end

    def is_singular?(str)
      str.singularize == str
    end

    def set_uploader_in_model
      @uploaders.each do |uploader|
        method_strategy = uploader.type == 'single' ? 'has_one_attached' : 'has_many_attached'
        uploader_name = uploader.name
        model_path = model_file_path(@model_class, @variable_subject)

        unless File.exist?(model_path)
          say "Skip attaching #{uploader_name}: model file not found: #{model_path}", :yellow
          next
        end

        content = File.read(model_path)

        # More robust check: look for has_one_attached/has_many_attached with the uploader name
        # Pattern matches: has_one_attached :name or has_one_attached :name, dependent: ...
        attachment_pattern = /#{Regexp.escape(method_strategy)}\s+:#{Regexp.escape(uploader_name)}\b/

        if content.match?(attachment_pattern)
          say "Skip attaching #{uploader_name}: already present in #{model_path}", :blue
          next
        end

        line_to_insert = "  #{method_strategy} :#{uploader_name}, dependent: :purge\n"
        class_anchor_regex = /class #{Regexp.escape(@model_class.to_s)} < ApplicationRecord[^\n]*\n/

        inject_into_file model_path, line_to_insert, after: class_anchor_regex
      end
    end

    def model_file_path(model_class, variable_subject)
      # Extract namespace dari model class
      # Models::User -> namespace setelah Models adalah []
      # Models::EngineName::User -> namespace setelah Models adalah [EngineName]
      full_namespace = model_class.to_s.deconstantize
      namespace_parts = full_namespace.split('::').reject(&:empty?)

      # Jika model_class mengandung Models::EngineName::User, maka path ke engine
      # Jika model_class Models::User, maka path ke main app
      if namespace_parts.length > 1 && namespace_parts.first == 'Models'
        # Engine: Models::EngineName::User -> app/models/<engine_name>/<model>.rb
        engine_name_part = namespace_parts[1].underscore
        File.join('app/models', engine_name_part, "#{variable_subject}.rb")
      else
        # Main app: Models::User -> app/models/models/<model>.rb
        File.join(RiderKick.configuration.models_path, "#{variable_subject}.rb")
      end
    end

    def generate_files(action, suffix = '')
      use_case_filename   = build_usecase_filename(action, suffix)
      repository_filename = build_repository_filename(action, suffix)

      @use_case_class   = use_case_filename.camelize
      @repository_class = repository_filename.camelize

      # Generate code files
      template "domains/core/use_cases/#{action + suffix}.rb.tt", File.join(RiderKick.configuration.domains_path, 'use_cases', @route_scope_path.to_s, @scope_path.to_s, "#{use_case_filename}.rb")
      template "domains/core/repositories/#{action + suffix}.rb.tt", File.join(RiderKick.configuration.domains_path, 'repositories', @scope_path.to_s, "#{repository_filename}.rb")

      # Generate spec files
      generate_use_case_spec(action, suffix, use_case_filename)
      generate_repository_spec(action, suffix, repository_filename)
    end

    def copy_builder_and_entity_files
      template 'domains/core/builders/builder.rb.tt', File.join(RiderKick.configuration.domains_path, 'builders', "#{@variable_subject}.rb")
      template 'domains/core/entities/entity.rb.tt', File.join(RiderKick.configuration.domains_path, 'entities', "#{@variable_subject}.rb")
    end

    def contract_fields
      @model_class.columns.reject { |c| ['id', 'created_at', 'updated_at', 'type'].include?(c.name.to_s) }
        .map { |c| c.name.to_s }
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

    def generate_use_case_spec(action, suffix, use_case_filename)
      template_name = "domains/core/use_cases/#{action + suffix}_spec.rb.tt"
      spec_path = File.join(RiderKick.configuration.domains_path, 'use_cases', @route_scope_path.to_s, @scope_path.to_s, "#{use_case_filename}_spec.rb")

      if File.exist?(File.join(self.class.source_root, template_name))
        template template_name, spec_path
      else
        say "Warning: Spec template not found: #{template_name}", :yellow
      end
    end

    def generate_repository_spec(action, suffix, repository_filename)
      template_name = "domains/core/repositories/#{action + suffix}_spec.rb.tt"
      spec_path = File.join(RiderKick.configuration.domains_path, 'repositories', @scope_path.to_s, "#{repository_filename}_spec.rb")

      if File.exist?(File.join(self.class.source_root, template_name))
        template template_name, spec_path
      else
        say "Warning: Spec template not found: #{template_name}", :yellow
      end
    end

    def generate_spec_files
      # Generate builder spec (covers entity validation too)
      builder_spec_path = File.join(RiderKick.configuration.domains_path, 'builders', "#{@variable_subject}_spec.rb")
      template 'domains/core/builders/builder_spec.rb.tt', builder_spec_path

      # Generate model spec
      generate_model_spec
    end

    def generate_model_spec
      model_spec_path = model_file_path(@model_class, @variable_subject).gsub('.rb', '_spec.rb')
      # Place spec in spec/models directory instead of app/models
      model_spec_path = model_spec_path.gsub('app/models', 'spec/models')

      template 'models/model_spec.rb.tt', model_spec_path
    end
  end
end
