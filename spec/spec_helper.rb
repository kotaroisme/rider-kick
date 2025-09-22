# frozen_string_literal: true

require "rider-kick"
Dir[File.join(__dir__, "support/**/*.rb")].sort.each { |f| require f }
RSpec.configure do |config|
  # Matikan infer bawaan (berbasis spec/...) karena kita co-locate
  config.infer_spec_type_from_file_location! if false

  # Tambahkan derived metadata berdasar path real di app/
  config.define_derived_metadata(file_path: %r{\Aapp/models/})       { |m| m[:type] = :model }
  config.define_derived_metadata(file_path: %r{\Aapp/services/})     { |m| m[:type] = :service }
  config.define_derived_metadata(file_path: %r{\Aapp/controllers/})  { |m| m[:type] = :controller }
  config.define_derived_metadata(file_path: %r{\Aapp/jobs/})         { |m| m[:type] = :job }
  config.define_derived_metadata(file_path: %r{\Aapp/})              { |m| m[:type] ||= :unit }

  # contoh: lib/ di-set ke :unit
  config.define_derived_metadata(file_path: %r{\Alib/})              { |m| m[:type] = :unit }
end