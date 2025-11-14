require_relative 'base_generator'
require_relative '../../rider-kick'

module RiderKick
  class CleanArchGenerator < BaseGenerator
    source_root File.expand_path('templates', __dir__)

    class_option :setup, type: :boolean, default: false, desc: 'Setup domain structure'
    class_option :engine, type: :string, default: nil, desc: 'Specify engine name (e.g., Core, Admin)'
    class_option :domain, type: :string, default: '', desc: 'Specify domain scope (e.g., core/, admin/, api/v1/)'

    def validate_setup_option
      # Jika --engine dispecify, maka --setup otomatis dianggap true
      return if options.engine.present?

      unless options.setup
        raise ValidationError.new(
                'The --setup option must be specified to create the domain structure.',
                suggestion: 'Run: bin/rails generate rider_kick:clean_arch --setup'
        )
      end
    end

    def create_gem_dependencies
      if options[:engine].present?
        # Untuk engine, tambahkan ke Gemfile engine
        engine_gemfile_path = "engines/#{options[:engine].downcase}/Gemfile"
        append_to_file(engine_gemfile_path, gem_dependencies)
        say "Gems added to #{engine_gemfile_path}", :green
      else
        # Untuk main app, tambahkan ke Gemfile host
        append_to_file('Gemfile', gem_dependencies)
        say 'Gems added to Gemfile', :green
      end
    end

    def setup_configuration
      configure_engine
      setup_domain_structure

      if options[:engine].present?
        # Untuk engine, hanya setup yang relevan
        setup_init_migration
        setup_models
        setup_engine_generators
      else
        # Untuk main app, setup semua
        setup_initializers
        setup_dotenv
        setup_gitignore
        setup_rubocop
        setup_init_migration
        setup_models
        setup_application_config
        # setup_active_storage
        setup_rspec
        setup_readme
      end
    end

    private

    def domain_class_name
      # Convert domain scope to class name
      # Engine: "<Engine>" for ApplicationRecord, "<Engine>::<Domain>" for other classes
      # Main app: "" for ApplicationRecord, "<AppName>" for root domain, "<Domain>" for scoped domain
      scope = RiderKick.configuration.domain_scope.chomp('/')

      if RiderKick.configuration.engine_name.present?
        # Engine context: domain_scope always starts with engine name
        engine_prefix = RiderKick.configuration.engine_name.to_s.camelize
        engine_underscored = RiderKick.configuration.engine_name.to_s.underscore

        if scope == engine_underscored
          # Default engine domain: engines/my_engine/app/domains/my_engine/
          engine_prefix
        else
          # Engine with sub-domain: engines/my_engine/app/domains/my_engine/admin/
          # Remove engine prefix from scope and create namespace
          sub_scope = scope.sub(/^#{engine_underscored}\//, '')
          if sub_scope.empty?
            engine_prefix
          else
            "#{engine_prefix}::#{sub_scope.split('/').map(&:camelize).join('::')}"
          end
        end
      elsif scope.empty?
        # Main app context
        # Root domain in main app: use application name
        begin
          Rails.application&.class&.module_parent_name || 'MyApp'
        rescue
          'MyApp' # Fallback for test environment
        end
      else
        # Scoped domain in main app: use domain name only
        scope.split('/').map(&:camelize).join('::')
      end
    end

    def domain_class_name_for_application_record
      # Special method for ApplicationRecord class names
      # Engine: "<Engine>" (will become EngineApplicationRecord)
      # Main app: "" (will become ApplicationRecord)
      if RiderKick.configuration.engine_name.present?
        # Engine context: use engine name
        RiderKick.configuration.engine_name.to_s.camelize
      else
        # Main app context: empty string for ApplicationRecord
        ''
      end
    end

    def setup_active_storage
      run 'rails active_storage:install'
      run 'rails db:migrate'
    end

    def setup_domain_structure
      empty_directory File.join(RiderKick.configuration.domains_path, 'use_cases/contract')
      empty_directory File.join(RiderKick.configuration.domains_path, 'repositories')
      empty_directory File.join(RiderKick.configuration.domains_path, 'builders')
      empty_directory File.join(RiderKick.configuration.domains_path, 'entities')
      empty_directory File.join(RiderKick.configuration.domains_path, 'utils')

      # then
      copy_domain_file
    end

    def copy_domain_file
      template 'domains/core/use_cases/contract/pagination.rb.tt', File.join(RiderKick.configuration.domains_path, 'use_cases/contract', 'pagination.rb')
      template 'domains/core/use_cases/contract/default.rb.tt', File.join(RiderKick.configuration.domains_path, 'use_cases/contract', 'default.rb')
      template 'domains/core/use_cases/get_version.rb.tt', File.join(RiderKick.configuration.domains_path, 'use_cases', 'get_version.rb')

      template 'domains/core/builders/error.rb.tt', File.join(RiderKick.configuration.domains_path, 'builders', 'error.rb')
      template 'domains/core/builders/pagination.rb.tt', File.join(RiderKick.configuration.domains_path, 'builders', 'pagination.rb')

      template 'domains/core/entities/error.rb.tt', File.join(RiderKick.configuration.domains_path, 'entities', 'error.rb')
      template 'domains/core/entities/pagination.rb.tt', File.join(RiderKick.configuration.domains_path, 'entities', 'pagination.rb')

      template 'domains/core/repositories/abstract_repository.rb.tt', File.join(RiderKick.configuration.domains_path, 'repositories', 'abstract_repository.rb')
      template 'domains/core/utils/abstract_utils.rb.tt', File.join(RiderKick.configuration.domains_path, 'utils', 'abstract_utils.rb')
      template 'domains/core/utils/request_methods.rb.tt', File.join(RiderKick.configuration.domains_path, 'utils', 'request_methods.rb')
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
      if options[:engine].present?
        # Untuk engine, buat migration dan structures directory di engine directory
        engine_migrate_path = "engines/#{options[:engine].downcase}/db/migrate"
        engine_structures_path = "engines/#{options[:engine].downcase}/db/structures"
        empty_directory engine_migrate_path unless Dir.exist?(engine_migrate_path)
        empty_directory engine_structures_path unless Dir.exist?(engine_structures_path)
        template 'db/migrate/20220613145533_init_database.rb', File.join(engine_migrate_path, '20220613145533_init_database.rb')
      else
        # Untuk main app, buat di root db/migrate dan db/structures
        template 'db/migrate/20220613145533_init_database.rb', File.join('db/migrate/20220613145533_init_database.rb')
        empty_directory 'db/structures' unless Dir.exist?('db/structures')
      end
    end

    # Helper untuk menyalin initializers
    def copy_initializer(file_name)
      template "config/initializers/#{file_name}.rb.tt", File.join("config/initializers/#{file_name}.rb")
    end

    def copy_database_config
      template 'config/database.yml', File.join('config/database.yml')
    end

    def setup_models
      if options[:engine].present?
        # Untuk engine, buat application_record.rb di engine directory
        engine_models_path = "engines/#{options[:engine].downcase}/app/models/#{options[:engine].downcase}"
        empty_directory engine_models_path unless Dir.exist?(engine_models_path)
        template 'models/application_record.rb', File.join(engine_models_path, 'application_record.rb')
      else
        # Untuk main app, buat di root app/models
        template 'models/application_record.rb', File.join('app/models/application_record.rb')
      end

      # Untuk engine, models path akan di engines/<engine_name>/app/models/<engine_name>/models
      # Untuk main app, models path akan di app/models/models
      models_dir = RiderKick.configuration.models_path
      empty_directory models_dir unless Dir.exist?(models_dir)
      template 'models/models.rb', File.join(models_dir, 'models.rb')
    end

    def copy_env_development
      template 'env.production', File.join('.env.production')
      template 'env.development', File.join('.env.development')
      template 'env.test', File.join('.env.test')
      template 'env.test', File.join('env.example')
    end

    def gem_dependencies
      <<~RUBY
        group :development, :test do
          gem "rspec-rails"
          gem "factory_bot_rails"
          gem "faker"
          gem "shoulda-matchers"
        end

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

    def setup_application_config
      application_config_path = 'config/application.rb'

      # Check if file exists
      unless File.exist?(application_config_path)
        say "File #{application_config_path} not found, skipping application config setup", :yellow
        return
      end

      # Check if config already exists
      application_content = File.read(application_config_path)
      if application_content.include?("config.paths['db/migrate']")
        say "Migration paths config already exists in #{application_config_path}", :green
        return
      end

      # Find the class Application block and inject config after class definition
      # Look for pattern: class Application < Rails::Application
      if /class\s+Application\s+<\s+Rails::Application/.match?(application_content)
        # Try to inject right after class definition line
        inject_into_file application_config_path, after: /class\s+Application\s+<\s+Rails::Application\s*\n/ do
          <<~RUBY
            # Load migrations from engines
            config.paths['db/migrate'] << './**/db/migrate'

          RUBY
        end
        say "Added migration paths config to #{application_config_path}", :green
      else
        say "Could not find Application class in #{application_config_path}, skipping", :yellow
      end
    end

    def setup_engine_generators
      engine_name_underscore = options[:engine].downcase
      options[:engine].camelize
      engine_rb_path = "engines/#{engine_name_underscore}/lib/#{engine_name_underscore}/engine.rb"

      # Check if file exists
      unless File.exist?(engine_rb_path)
        say "File #{engine_rb_path} not found, skipping engine generators config setup", :yellow
        return
      end

      # Check if config already exists
      engine_content = File.read(engine_rb_path)
      if engine_content.include?('config.generators do |generate|')
        say "Generator config already exists in #{engine_rb_path}", :green
        return
      end

      # Find the engine class definition and inject config inside it
      # Look for pattern: class Engine < Rails::Engine (inside module)
      if /class\s+Engine\s+<\s+::Rails::Engine/.match?(engine_content)
        # Try to inject right after the class definition line
        inject_into_file engine_rb_path, after: /class\s+Engine\s+<\s+::Rails::Engine\s*\n/ do
          <<~RUBY
            config.generators do |generate|
              generate.orm :active_record, primary_key_type: :uuid
              generate.assets = false
              generate.helper = false
              generate.test_framework nil
            end

          RUBY
        end
        say "Added generator config to #{engine_rb_path}", :green
      else
        say "Could not find Engine class in #{engine_rb_path}, skipping", :yellow
      end
    end
  end
end
