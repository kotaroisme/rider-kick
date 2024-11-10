module RiderKick
  class CleanArchGenerator < Rails::Generators::Base
    source_root File.expand_path('templates', __dir__)

    class_option :setup, type: :boolean, default: false, desc: 'Setup domain structure'

    def validate_setup_option
      raise Thor::Error, 'The --setup option must be specified to create the domain structure.' unless options.setup
    end

    def create_gem_dependencies
      append_to_file('Gemfile', gem_dependencies)
      say 'Gems added to Gemfile', :green
    end

    def setup_configuration
      setup_domain_structure

      setup_initializers
      setup_dotenv
      setup_gitignore
      setup_rubocop
      setup_init_migration
      setup_readme
    end

    private

    def setup_domain_structure
      empty_directory File.join("#{path_app}/domains/core/use_cases/contract")
      empty_directory File.join("#{path_app}/domains/core/repositories")
      empty_directory File.join("#{path_app}/domains/core/builders")
      empty_directory File.join("#{path_app}/domains/core/entities")
      empty_directory File.join("#{path_app}/domains/core/utils")

      # then
      copy_domain_file
    end

    def copy_domain_file
      template 'domains/core/use_cases/contract/pagination.rb.tt', File.join("#{path_app}/domains/core/use_cases/contract", 'pagination.rb')
      template 'domains/core/use_cases/contract/default.rb.tt', File.join("#{path_app}/domains/core/use_cases/contract", 'default.rb')
      template 'domains/core/use_cases/get_version.rb.tt', File.join("#{path_app}/domains/core/use_cases", 'get_version.rb')

      template 'domains/core/builders/error.rb.tt', File.join("#{path_app}/domains/core/builders", 'error.rb')
      template 'domains/core/builders/pagination.rb.tt', File.join("#{path_app}/domains/core/builders", 'pagination.rb')

      template 'domains/core/entities/error.rb.tt', File.join("#{path_app}/domains/core/entities", 'error.rb')
      template 'domains/core/entities/pagination.rb.tt', File.join("#{path_app}/domains/core/entities", 'pagination.rb')

      template 'domains/core/repositories/abstract_repository.rb.tt', File.join("#{path_app}/domains/core/repositories", 'abstract_repository.rb')
      template 'domains/core/utils/request_methods.rb.tt', File.join("#{path_app}/domains/core/utils", 'request_methods.rb')
    end

    def setup_initializers
      copy_initializer('hashie')
      copy_initializer('types')
      copy_initializer('version')
    end

    def setup_dotenv
      copy_database_config
      copy_env_development
    end

    def setup_gitignore
      template '.gitignore', File.join('.gitignore')
    end

    def setup_rubocop
      template '.rubocop.yml', File.join('.rubocop.yml')
    end

    def setup_readme
      template 'README.md', File.join('README.md')
    end

    def setup_init_migration
      template 'db/migrate/20220613145533_init_database.rb', File.join('db/migrate/20220613145533_init_database.rb')
    end

    # Helper untuk menyalin initializers
    def copy_initializer(file_name)
      template "config/initializers/#{file_name}.rb.tt", File.join("config/initializers/#{file_name}.rb")
    end

    def copy_database_config
      template 'config/database.yml', File.join('config/database.yml')
    end

    def copy_env_development
      template 'env.production', File.join('.env.production')
      template 'env.development', File.join('.env.development')
      template 'env.test', File.join('.env.test')
      template 'env.test', File.join('env.example')
    end

    def gem_dependencies
      <<~RUBY

        # Env Variables
        gem 'dotenv-rails'

        # Objectable
        gem 'hashie'
      RUBY
    end

    def path_app
      'app'
    end
  end
end
