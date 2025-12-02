#!/usr/bin/env ruby

# Add lib to path
$LOAD_PATH.unshift(File.expand_path('lib', __dir__))

require 'rider_kick/configuration'

puts "=== Testing RiderKick Configuration ==="
puts ""

# Create configuration instance
config = RiderKick::Configuration.new

# Test default
puts "Default configuration:"
puts "Domain scope: #{config.domain_scope}"
puts "Domains path: #{config.domains_path}"
puts "Entities path: #{config.entities_path}"
puts "Adapters path: #{config.adapters_path}"
puts ""

# Test domain scope change to admin
puts "After setting domain_scope = 'admin/':"
config.domain_scope = 'admin/'
puts "Domain scope: #{config.domain_scope}"
puts "Domains path: #{config.domains_path}"
puts "Entities path: #{config.entities_path}"
puts "Adapters path: #{config.adapters_path}"
puts ""

# Test domain scope change to api/v1
puts "After setting domain_scope = 'api/v1/':"
config.domain_scope = 'api/v1/'
puts "Domain scope: #{config.domain_scope}"
puts "Domains path: #{config.domains_path}"
puts "Entities path: #{config.entities_path}"
puts "Adapters path: #{config.adapters_path}"
puts ""

puts "=== Test Complete ==="
