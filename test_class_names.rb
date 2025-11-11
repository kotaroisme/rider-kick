#!/usr/bin/env ruby

# Test script untuk memverifikasi class names yang di-generate
$LOAD_PATH.unshift(File.expand_path('lib', __dir__))
require 'rider_kick/configuration'

puts "=== Testing Domain Class Name Conversion ==="
puts ""

# Test cases
test_cases = [
  { scope: 'core/', expected: 'Core' },
  { scope: 'admin/', expected: 'Admin' },
  { scope: 'api/v1/', expected: 'Api::V1' },
  { scope: 'mobile/app/', expected: 'Mobile::App' },
  { scope: 'fulfillment/order/', expected: 'Fulfillment::Order' }
]

test_cases.each do |test_case|
  # Simulate what happens in generator
  scope = test_case[:scope].chomp('/')
  domain_class = scope.split('/').map(&:camelize).join('::')

  result = domain_class == test_case[:expected] ? '✅ PASS' : '❌ FAIL'
  puts "#{test_case[:scope].ljust(15)} → #{domain_class.ljust(15)} (expected: #{test_case[:expected]}) #{result}"
end

puts ""
puts "=== Sample Generated Classes ==="
puts ""

# Test dengan domain admin
domain_scope = 'admin/'
scope = domain_scope.chomp('/')
domain_class = scope.split('/').map(&:camelize).join('::')

puts "Domain scope: #{domain_scope}"
puts "Domain class: #{domain_class}"
puts ""
puts "Generated classes:"
puts "  #{domain_class}::UseCases::Contract::Default"
puts "  #{domain_class}::UseCases::GetVersion"
puts "  #{domain_class}::Repositories::AbstractRepository"
puts "  #{domain_class}::Builders::Error"
puts "  #{domain_class}::Entities::Error"
puts "  #{domain_class}::Utils::RequestMethods"

puts ""
puts "=== Test Complete ==="
