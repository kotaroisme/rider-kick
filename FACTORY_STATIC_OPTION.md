# Factory Generator: Static Option Guide

## Overview

The `--static` option allows you to generate factories with pre-evaluated static values instead of Faker method calls. This is useful for creating consistent, reproducible test data.

## Command Comparison

### Without --static (Default Behavior)
```bash
rails generate rider_kick:factory Models::Article scope:core
```

**Generated Factory:**
```ruby
FactoryBot.define do
  factory :article, class: 'Models::Article' do
    title { Faker::Lorem.sentence(word_count: 3) }
    content { Faker::Lorem.paragraph(sentence_count: 3) }
    summary { Faker::Lorem.sentence }
    published { [true, false].sample }
    views_count { Faker::Number.between(from: 1, to: 100) }
  end
end
```

**Runtime Behavior:**
- Each time `create(:article)` is called, new random values are generated
- `title` will be different on every test run
- `published` will randomly be true or false

### With --static
```bash
rails generate rider_kick:factory Models::Article scope:core --static
```

**Generated Factory:**
```ruby
FactoryBot.define do
  factory :article, class: 'Models::Article' do
    title { 'Sit voluptatem aut' }
    content { 'Quia et et. Quis ut quo. Aut voluptas id.' }
    summary { 'Earum rerum hic tenetur.' }
    published { true }
    views_count { 42 }
    # Note: datetime/timestamp/time fields still use Time.zone.now even with --static
    published_at { Time.zone.now }
  end
end
```

**Runtime Behavior:**
- Each time `create(:article)` is called, the same values are used
- `title` will always be 'Sit voluptatem aut'
- `published` will always be true
- **Exception:** Time fields (`published_at`) will still be dynamic with `Time.zone.now`

## Detailed Examples

### Example 1: User Model

**Model Definition:**
```ruby
class Models::User < ApplicationRecord
  # Columns: email, full_name, age, phone_number, city, active
end
```

**Standard Factory:**
```bash
rails generate rider_kick:factory Models::User scope:core
```

```ruby
FactoryBot.define do
  factory :user, class: 'Models::User' do
    email { Faker::Internet.email }
    full_name { Faker::Name.name }
    age { Faker::Number.between(from: 18, to: 80) }
    phone_number { Faker::PhoneNumber.phone_number }
    city { Faker::Address.city }
    active { [true, false].sample }
  end
end
```

**Static Factory:**
```bash
rails generate rider_kick:factory Models::User scope:core --static
```

```ruby
FactoryBot.define do
  factory :user, class: 'Models::User' do
    email { 'john.doe@example.com' }
    full_name { 'John Doe' }
    age { 35 }
    phone_number { '555-123-4567' }
    city { 'New York' }
    active { true }
  end
end
```

### Example 2: Product Model

**Model Definition:**
```ruby
class Models::Product < ApplicationRecord
  # Columns: name, description, price, stock_count, available
end
```

**Standard Factory:**
```ruby
FactoryBot.define do
  factory :product, class: 'Models::Product' do
    name { Faker::Name.name }
    description { Faker::Lorem.paragraph(sentence_count: 3) }
    price { Faker::Commerce.price }
    stock_count { Faker::Number.between(from: 1, to: 100) }
    available { [true, false].sample }
  end
end
```

**Static Factory:**
```ruby
FactoryBot.define do
  factory :product, class: 'Models::Product' do
    name { 'Jane Smith' }
    description { 'Lorem ipsum dolor sit amet. Consectetur adipiscing elit. Sed do eiusmod tempor.' }
    price { 99.99 }
    stock_count { 50 }
    available { true }
  end
end
```

### Example 3: Event Model (with DateTime fields)

**Model Definition:**
```ruby
class Models::Event < ApplicationRecord
  # Columns: title, description, start_time, end_time, published_at
end
```

**Standard Factory:**
```ruby
FactoryBot.define do
  factory :event, class: 'Models::Event' do
    title { Faker::Lorem.sentence(word_count: 3) }
    description { Faker::Lorem.paragraph(sentence_count: 3) }
    start_time { Time.zone.now }
    end_time { Time.zone.now }
    published_at { Time.zone.now }
  end
end
```

**Static Factory:**
```ruby
FactoryBot.define do
  factory :event, class: 'Models::Event' do
    title { 'Quo sed rerum' }
    description { 'Et vitae et. Voluptatem quia aut. Sit dolor non.' }
    start_time { Time.zone.now }
    end_time { Time.zone.now }
    published_at { Time.zone.now }
  end
end
```

**Note about Time fields:**
- All `datetime`, `timestamp`, and `time` columns use `Time.zone.now`
- This ensures timezone-aware timestamps
- **Important:** Time fields are NEVER evaluated to static values, even with `--static` flag
- They always remain as `Time.zone.now` for both standard and static factories
- This ensures tests always use current time and respect timezone settings

## Use Cases

### When to Use --static

#### 1. Debugging Specific Test Cases
```ruby
# With static factory, you always know the exact values
describe 'User validation' do
  it 'validates email format' do
    user = build(:user)
    expect(user.email).to eq('john.doe@example.com') # Always consistent
    expect(user).to be_valid
  end
end
```

#### 2. Testing Business Logic with Specific Values
```ruby
# When you need exact values for business logic
describe 'Order total calculation' do
  it 'calculates correct total' do
    product = create(:product) # price is always 99.99
    order = create(:order, product: product, quantity: 2)
    expect(order.total).to eq(199.98) # Predictable calculation
  end
end
```

#### 3. Snapshot Testing
```ruby
# When testing output that should remain consistent
describe 'User profile export' do
  it 'exports correct format' do
    user = create(:user)
    export = UserExporter.new(user).to_csv
    expect(export).to match_snapshot # Always same output
  end
end
```

#### 4. Creating Seed Data or Fixtures
```ruby
# For manual testing or demos
namespace :demo do
  task setup: :environment do
    # Creates predictable demo users
    admin = create(:user, role: :admin)
    puts "Created admin: #{admin.email}" # Always same email
  end
end
```

### When NOT to Use --static

#### 1. Testing with Varied Data
```ruby
# When you want to test with different data combinations
describe 'User search' do
  it 'finds users by partial name' do
    10.times { create(:user) } # Each has different name
    # Tests search across varied data
  end
end
```

#### 2. Catching Edge Cases
```ruby
# Random data might reveal edge cases you didn't expect
describe 'Email validation' do
  it 'accepts valid emails' do
    100.times do
      user = build(:user) # Different email each time
      expect(user).to be_valid
    end
  end
end
```

#### 3. Load/Performance Testing
```ruby
# When testing with high volume of varied data
describe 'Database performance' do
  it 'handles large datasets efficiently' do
    users = create_list(:user, 1000) # All different
    expect(User.search(query).count).to be > 0
  end
end
```

## Customizing Static Values

After generating a static factory, you can easily customize the values:

```ruby
# Generated with --static
FactoryBot.define do
  factory :user, class: 'Models::User' do
    email { 'john.doe@example.com' }
    full_name { 'John Doe' }
    age { 35 }
  end
end

# Customize to your needs
FactoryBot.define do
  factory :user, class: 'Models::User' do
    email { 'test.user@myapp.com' }      # Real email format for your app
    full_name { 'Test User' }            # Clear test user name
    age { 25 }                           # Specific age for your tests
  end
end
```

## Mixing Static and Dynamic Values

You can also mix static and dynamic values in the same factory:

```ruby
FactoryBot.define do
  factory :user, class: 'Models::User' do
    email { 'test.user@myapp.com' }      # Static for consistency
    full_name { Faker::Name.name }       # Dynamic for variety
    age { 25 }                           # Static for business logic
    phone_number { Faker::PhoneNumber.phone_number } # Dynamic
  end
end
```

## Best Practices

### 1. Use --static for Core Test Data
```ruby
# Core user types with predictable data
factory :admin_user, class: 'Models::User' do
  email { 'admin@example.com' }
  full_name { 'Admin User' }
  role { 'admin' }
end
```

### 2. Use Dynamic for Bulk Data
```ruby
# Regular users with varied data
factory :user, class: 'Models::User' do
  email { Faker::Internet.email }
  full_name { Faker::Name.name }
  role { 'user' }
end
```

### 3. Document Your Factories
```ruby
# frozen_string_literal: true

# Static factory for consistent test data
# Used in: user authentication specs, profile specs
# Generated with: rails g rider_kick:factory Models::User --static
FactoryBot.define do
  factory :user, class: 'Models::User' do
    email { 'test.user@example.com' }
    full_name { 'Test User' }
    # ... rest of attributes
  end
end
```

## Regenerating Factories

If you want different static values, simply regenerate:

```bash
# Generate new static values
rails generate rider_kick:factory Models::Article scope:core --static

# This will create a new factory with different random values
```

## Summary

| Aspect | Without --static | With --static |
|--------|------------------|---------------|
| **Command** | `rails g rider_kick:factory Model` | `rails g rider_kick:factory Model --static` |
| **Values** | Faker method calls | Pre-evaluated static values |
| **Consistency** | Different each run | Same every run |
| **Use Case** | Varied test data | Reproducible tests |
| **Debugging** | Harder (random values) | Easier (known values) |
| **Flexibility** | High | Medium |
| **Customization** | Faker options | Direct value editing |
| **Best For** | General testing | Specific scenarios |

## Conclusion

The `--static` option provides flexibility in how you generate test data:

- **Default (no --static)**: Best for general testing with varied, random data
- **With --static**: Best for debugging, specific test cases, and reproducible scenarios

Choose the option that best fits your testing needs, or use both approaches in different parts of your test suite!

