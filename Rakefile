# Rakefile
require 'rspec/core/rake_task'

RSpec::Core::RakeTask.new(:spec) do |t|
  t.pattern = '{app,lib}/**/*_spec.rb'
end

task default: :spec