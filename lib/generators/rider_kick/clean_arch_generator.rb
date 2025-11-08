module RiderKick
  class CleanArchGenerator < Rails::Generators::Base
    source_root File.expand_path('templates', __dir__)

    class_option :setup, type: :boolean, default: false, desc: 'Setup domain structure'
    class_option :engine, type: :string, default: nil, desc: 'Specify engine name (e.g., Core, Admin)'

    def validate_setup_option
      raise Thor::Error, 'The --setup option must be specified to create the domain structure.' unless options.setup
    end

    def create_gem_dependencies
      append_to_file('Gemfile', gem_dependencies)
      say 'Gems added to Gemfile', :green
    end

    def setup_configuration
      configure_engine
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
      template 'domains/core/utils/abstract_utils.rb.tt', File.join("#{path_app}/domains/core/utils", 'abstract_utils.rb')
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

      # Untuk engine, models path akan di app/models/<engine_name>
      # Untuk main app, models path akan di app/models/models
      models_dir = RiderKick.configuration.models_path
      empty_directory models_dir unless Dir.exist?(models_dir)
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

  gem "rspec-rails"
  gem "factory_bot_rails"
  gem "faker"
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
      template 'spec/support/class_stubber.rb', File.join('spec/support/class_stubber.rb')
      say 'Mengonfigurasi FactoryBot dan Faker...'
      setup_factory_bot
      template 'spec/rails_helper.rb', File.join('spec/rails_helper.rb')
    end

    def setup_factory_bot
      # Create factories directory structure
      empty_directory 'spec/factories'

      # Create FactoryBot support file
      template 'spec/support/factory_bot.rb', File.join('spec/support/factory_bot.rb')

      # Create Faker support file
      template 'spec/support/faker.rb', File.join('spec/support/faker.rb')

      # Create example factories file
      template 'spec/factories/.gitkeep', File.join('spec/factories/.gitkeep')
    end

    def path_app
      'app'
    end
  end
end
