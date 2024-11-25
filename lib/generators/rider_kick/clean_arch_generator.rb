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
      setup_models
      setup_active_storage
      setup_rspec
      setup_readme
    end

    private

    def setup_active_storage
      run 'rails active_storage:install'
      run 'rails db:migrate'
    end

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
      copy_initializer('clean_archithecture')
      copy_initializer('generators')
      copy_initializer('hashie')
      copy_initializer('version')
      copy_initializer('zeitwerk')
      copy_initializer('pagy')
      copy_initializer('route_extensions')
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

    def setup_models
      template 'models/application_record.rb', File.join('app/models/application_record.rb')
      template 'models/models.rb', File.join('app/models/models.rb')
    end

    def copy_env_development
      template 'env.production', File.join('.env.production')
      template 'env.development', File.join('.env.development')
      template 'env.test', File.join('.env.test')
      template 'env.test', File.join('env.example')
    end

    def gem_dependencies
      inject_into_file 'Gemfile', after: "group :development, :test do\n" do
        <<-CONFIG

  gem "byebug"
  gem "rspec-rails"
  gem "factory_bot_rails"
  gem "shoulda-matchers"
        CONFIG
      end

      <<~RUBY

        # Env Variables
        gem 'dotenv-rails'

        # Objectable
        gem 'hashie'

        # uploading
        gem 'image_processing', '>= 1.2'
        gem 'ruby-vips'

        # pagination
        gem 'pagy', '~> 9.2'
      RUBY
    end

    def setup_rspec
      say 'Menjalankan bundle install...'
      run 'bundle install'
      say 'Menginisialisasi RSpec...'
      run 'rails generate rspec:install'
      template '.rspec', File.join('.rspec')
      template 'spec/support/repository_stubber.rb', File.join('spec/support/repository_stubber.rb')
      template 'spec/support/file_stuber.rb', File.join('spec/support/file_stuber.rb')
      say 'Mengonfigurasi FactoryBot...'
      template 'spec/rails_helper.rb', File.join('spec/rails_helper.rb')
    end

    def path_app
      'app'
    end
  end
end
