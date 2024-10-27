module RiderKick
  class BlankGenerator < Rails::Generators::Base
    source_root File.expand_path('templates', __dir__)

    class_option :use_case, type: :boolean, default: false, desc: 'Generate Use Case domain structure'
    class_option :repository, type: :boolean, default: false, desc: 'Generate Repository domain structure'
    class_option :builder, type: :boolean, default: false, desc: 'Generate Builder domain structure'
    class_option :entity, type: :boolean, default: false, desc: 'Generate Entity domain structure'
    argument :arg_options, type: :hash, default: '', banner: 'actor:user action:create scope:Contact'

    def generate_use_case
      setup_variables
      generate_files(arg_options['action'], @variable_subject)
    end

    private

    def setup_variables
      @variable_subject = arg_options['scope'].underscore.downcase
      @model_class      = arg_options['scope'].camelize
      @subject_class    = @model_class
      @scope_path       = @variable_subject
      @builder          = options.builder
    end

    def generate_files(action, scope = '')
      use_case_filename   = build_usecase_filename(action, scope)
      repository_filename = build_repository_filename(action, scope)

      @scope_class      = @scope_path.camelize
      @use_case_class   = use_case_filename.camelize
      @repository_class = repository_filename.camelize

      template 'domains/core/use_cases/blank.rb.tt', File.join("#{root_path_app}/domains/core/use_cases/#{@scope_path}", "#{use_case_filename}.rb") if options.use_case
      template 'domains/core/repositories/blank.rb.tt', File.join("#{root_path_app}/domains/core/repositories/#{@scope_path}", "#{repository_filename}.rb") if options.repository
      template 'domains/core/builders/blank.rb.tt', File.join("#{root_path_app}/domains/core/builders", "#{@variable_subject}.rb") if options.builder
      template 'domains/core/entities/blank.rb.tt', File.join("#{root_path_app}/domains/core/entities", "#{@variable_subject}.rb") if options.entity || options.builder
    end

    def root_path_app
      'app'
    end

    def build_usecase_filename(action, scope = '')
      "#{arg_options['actor'].downcase}_#{action}_#{scope}"
    end

    def build_repository_filename(action, scope = '')
      "#{action}_#{scope}"
    end
  end
end
