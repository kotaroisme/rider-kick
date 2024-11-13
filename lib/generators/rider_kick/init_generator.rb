module RiderKick
  class InitGenerator < Rails::Generators::Base
    source_root File.expand_path('templates', __dir__)

    def setup_configuration
      copy_initializer('rider_kick')
    end

    private

    def copy_initializer(file_name)
      template "config/initializers/#{file_name}.rb", File.join("config/initializers/#{file_name}.rb")
    end
  end
end
