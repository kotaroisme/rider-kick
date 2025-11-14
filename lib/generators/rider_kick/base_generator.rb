# frozen_string_literal: true

require 'rails/generators'
require 'active_support/inflector'
require 'active_support/core_ext/object/blank'
require 'yaml'
require_relative 'errors'
require_relative '../../rider-kick'

module RiderKick
  class BaseGenerator < Rails::Generators::Base
    protected

    def template_path_for(template_name)
      # Check for custom template path first
      custom_path = RiderKick.configuration.template_path
      if custom_path && Dir.exist?(custom_path)
        custom_template_path = File.join(custom_path, template_name)
        return custom_template_path if File.exist?(custom_template_path)
      end
      # Fallback to default template path
      File.join(self.class.source_root, template_name)
    end

    def configure_engine
      if options[:engine].present?
        RiderKick.configuration.engine_name = options[:engine]
        # Jika --engine dispecify, selalu ada scope engine nya
        engine_prefix = options[:engine].underscore
        domain_part = options[:domain] || ''
        RiderKick.configuration.domain_scope = domain_part.empty? ? engine_prefix + '/' : engine_prefix + '/' + domain_part
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

    def validate_file_exists!(path, context = '')
      unless File.exist?(path)
        error_message = "File not found: #{path}"
        error_message += " (#{context})" if context.present?
        raise FileNotFoundError.new(error_message, file_path: path, context: context)
      end
    end

    def validate_yaml_format!(file_path)
      validate_file_exists!(file_path, 'YAML validation')
      begin
        YAML.load_file(file_path)
      rescue Psych::SyntaxError => e
        raise YamlFormatError.new(
          "Invalid YAML format in #{file_path}: #{e.message}",
          file_path: file_path,
          yaml_error: e.message
        )
      rescue => e
        raise YamlFormatError.new(
          "Error reading YAML file #{file_path}: #{e.message}",
          file_path: file_path,
          error: e.message
        )
      end
    end

    def validate_model_exists!(model_name)
      # Try to constantize the model name
      # This will raise NameError if the model doesn't exist
      begin
        model_name.constantize
      rescue NameError => e
        # Try to load the model file if it exists (for test scenarios where file exists but not loaded)
        model_path = find_model_file(model_name)
        if model_path && File.exist?(model_path)
          # Try loading the file
          begin
            load model_path
            model_name.constantize
          rescue => load_error
            # If loading also fails, raise the original error
            raise ModelNotFoundError.new(
              "Model #{model_name} not found. Make sure the model exists and is valid.",
              model_name: model_name,
              original_error: e.message,
              load_error: load_error.message
            )
          end
        else
          # Model file doesn't exist, raise error
          raise ModelNotFoundError.new(
            "Model #{model_name} not found. Make sure the model exists.",
            model_name: model_name,
            original_error: e.message
          )
        end
      end
    end

    def find_model_file(model_name)
      # Convert model name to file path
      # Models::User -> app/models/models/user.rb or engines/.../app/models/.../user.rb
      parts = model_name.split('::')
      return nil if parts.empty?

      file_name = parts.last.underscore + '.rb'
      
      # Check main app models path first
      main_path = File.join(RiderKick.configuration.models_path, file_name)
      return main_path if File.exist?(main_path)

      # Check engine models path if engine is set
      if RiderKick.configuration.engine_name
        engine_path = File.join(
          'engines',
          RiderKick.configuration.engine_name.underscore,
          'app/models',
          RiderKick.configuration.engine_name.underscore,
          'models',
          file_name
        )
        return engine_path if File.exist?(engine_path)
      end

      nil
    end

    def validate_domains_path!
      unless Dir.exist?(RiderKick.configuration.domains_path)
        raise ValidationError.new(
          'Clean architecture structure not found. Run: bin/rails generate rider_kick:clean_arch --setup',
          domains_path: RiderKick.configuration.domains_path
        )
      end
    end

    def detect_engine_name
      # Detect engine dari struktur file system
      # Cek apakah ada lib/<name>/engine.rb
      return nil unless Dir.exist?('lib')

      engines = []
      Dir.glob('lib/*/engine.rb').each do |engine_file|
        engine_name = File.basename(File.dirname(engine_file))
        engines << engine_name.camelize if File.exist?(engine_file)
      end

      # Jika hanya ada satu engine, return itu
      return engines.first if engines.length == 1

      # Jika ada multiple engines, return nil (user harus specify via --engine option)
      # Atau cek dari gem name di gemspec (fallback)
      gemspec_files = Dir.glob('*.gemspec')
      unless gemspec_files.empty?
        gemspec_content = File.read(gemspec_files.first)
        if gemspec_content =~ /\.name\s*=\s*["']([^"']+)["']/
          gem_name = Regexp.last_match(1)
          # Extract engine name dari gem name (e.g., "my_app-core" -> "Core")
          engine_name = gem_name.split(/[-_]/).last.camelize
          return engine_name if Dir.exist?("lib/#{engine_name.underscore}") && engines.include?(engine_name)
        end
      end

      nil
    end

    def detect_domains_path
      if RiderKick.configuration.engine_name
        # Engine: engines/<engine_name>/app/domains/<domain_scope>
        File.join('engines', RiderKick.configuration.engine_name.underscore, 'app/domains', RiderKick.configuration.domain_scope)
      else
        # Main app: app/domains/<domain_scope>
        File.join('app/domains', RiderKick.configuration.domain_scope)
      end
    end
  end
end

