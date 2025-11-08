# Factory Generator Documentation

## Overview

The Factory Generator creates FactoryBot factories for your models with intelligent Faker value generation. It automatically skips foreign key columns (ending with `_id`) and generates appropriate test data based on column types and names.

## Usage

### Basic Command

```bash
rails generate rider_kick:factory Models::Article scope:core
```

This will create: `spec/factories/core/article.rb`

### Without Scope

```bash
rails generate rider_kick:factory Models::Article
```

This will create: `spec/factories/article.rb`

### With Static Values (--static)

By default, the generator creates factories with Faker method calls that generate random values each time. Use the `--static` flag to generate factories with pre-evaluated static values:

```bash
# Generate factory with Faker calls (default)
rails generate rider_kick:factory Models::Article scope:core

# Generate factory with static values
rails generate rider_kick:factory Models::Article scope:core --static
```

**Standard Factory (without --static):**
```ruby
FactoryBot.define do
  factory :article, class: 'Models::Article' do
    title { Faker::Lorem.sentence(word_count: 3) }
    full_name { Faker::Name.name }
    email { Faker::Internet.email }
    age { Faker::Number.between(from: 18, to: 80) }
    published { [true, false].sample }
  end
end
```

**Static Factory (with --static):**
```ruby
FactoryBot.define do
  factory :article, class: 'Models::Article' do
    title { 'Sit voluptatem aut' }
    full_name { 'John Doe' }
    email { 'user123@example.com' }
    age { 42 }
    published { true }
  end
end
```

**When to use --static:**
- ✅ When you want consistent, reproducible test data
- ✅ When you're debugging and need the same values every time
- ✅ When you want to quickly see what kind of data will be generated
- ✅ When you want to customize specific values after generation

**When to use default (without --static):**
- ✅ When you want random, varied test data
- ✅ When testing with different data combinations
- ✅ When you want to catch edge cases with varied inputs
- ✅ For more realistic test scenarios with diverse data

**Important Note about Time Fields:**
- ⚠️ `datetime`, `timestamp`, and `time` columns always use `Time.zone.now`
- This applies to BOTH standard and `--static` modes
- Time fields are never evaluated to static string values
- This ensures timezone-aware timestamps and current time in all tests

📖 **[Complete Static Option Guide with Examples →](FACTORY_STATIC_OPTION.md)**

## Features

### 1. Automatic Foreign Key Skipping

All columns ending with `_id` are automatically excluded from the factory:

```ruby
# Given a model with: title, content, user_id, category_id, author_id
# Only title and content will be included in the factory
```

### 2. Smart Faker Value Generation

The generator intelligently selects Faker methods based on:
- **Column type** (string, text, integer, boolean, date, etc.)
- **Column name** (email, phone, url, description, etc.)

#### String Fields

| Column Name Pattern | Generated Faker |
|---------------------|----------------|
| `*email*` | `Faker::Internet.email` |
| `*name*` | `Faker::Name.name` |
| `*phone*` | `Faker::PhoneNumber.phone_number` |
| `*address*` | `Faker::Address.full_address` |
| `*city*` | `Faker::Address.city` |
| `*country*` | `Faker::Address.country` |
| `*url*` or `*website*` | `Faker::Internet.url` |
| `*title*` | `Faker::Lorem.sentence(word_count: 3)` |
| `*code*` | `Faker::Alphanumeric.alphanumeric(number: 10)` |
| Default | `Faker::Lorem.word` |

#### Text Fields

| Column Name Pattern | Generated Faker |
|---------------------|----------------|
| `*description*`, `*content*`, `*body*` | `Faker::Lorem.paragraph(sentence_count: 3)` |
| Default | `Faker::Lorem.sentence` |

#### Integer Fields

| Column Name Pattern | Generated Faker |
|---------------------|----------------|
| `*count*`, `*quantity*` | `Faker::Number.between(from: 1, to: 100)` |
| `*age*` | `Faker::Number.between(from: 18, to: 80)` |
| `*price*`, `*amount*` | `Faker::Number.between(from: 1000, to: 1000000)` |
| Default | `Faker::Number.number(digits: 5)` |

#### Other Types

| Type | Generated Value |
|------|----------------|
| `boolean` | `[true, false].sample` |
| `date` | `Faker::Date.between(from: 1.year.ago, to: Date.today)` |
| `datetime`, `timestamp`, `time` | `Time.zone.now` |
| `decimal` (price/amount) | `Faker::Commerce.price` |
| `decimal` (other) | `Faker::Number.decimal(l_digits: 4, r_digits: 2)` |
| `float` | `Faker::Number.decimal(l_digits: 2, r_digits: 2)` |
| `uuid` | `SecureRandom.uuid` |
| `json`, `jsonb` | `{ key: Faker::Lorem.word, value: Faker::Lorem.sentence }` |
| `inet` | `Faker::Internet.ip_v4_address` |

## Examples

### Example 1: Article Model

Given a model:

```ruby
class Models::Article < ApplicationRecord
  # Columns: id, title, content, summary, user_id, category_id, published, views_count, created_at, updated_at
end
```

Command:

```bash
rails generate rider_kick:factory Models::Article scope:core
```

Generated file (`spec/factories/core/article.rb`):

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

**Note:** `user_id`, `category_id`, `created_at`, `updated_at`, and `id` are automatically skipped.

### Example 2: Product Model

Given a model:

```ruby
class Models::Product < ApplicationRecord
  # Columns: id, name, description, price, stock_count, sku_code, available, category_id, created_at, updated_at
end
```

Command:

```bash
rails generate rider_kick:factory Models::Product scope:admin
```

Generated file (`spec/factories/admin/product.rb`):

```ruby
FactoryBot.define do
  factory :product, class: 'Models::Product' do
    name { Faker::Name.name }
    description { Faker::Lorem.paragraph(sentence_count: 3) }
    price { Faker::Commerce.price }
    stock_count { Faker::Number.between(from: 1, to: 100) }
    sku_code { Faker::Alphanumeric.alphanumeric(number: 10) }
    available { [true, false].sample }
  end
end
```

### Example 3: User Model

Given a model:

```ruby
class Models::User < ApplicationRecord
  # Columns: id, email, full_name, phone_number, age, city, country, bio, created_at, updated_at
end
```

Command:

```bash
rails generate rider_kick:factory Models::User scope:core
```

Generated file (`spec/factories/core/user.rb`):

```ruby
FactoryBot.define do
  factory :user, class: 'Models::User' do
    email { Faker::Internet.email }
    full_name { Faker::Name.name }
    phone_number { Faker::PhoneNumber.phone_number }
    age { Faker::Number.between(from: 18, to: 80) }
    city { Faker::Address.city }
    country { Faker::Address.country }
    bio { Faker::Lorem.sentence }
  end
end
```

## Using Generated Factories

Once generated, you can use the factories in your tests:

```ruby
# Create a single instance
article = create(:article)

# Create multiple instances
articles = create_list(:article, 5)

# Build without saving
article = build(:article)

# With custom attributes
article = create(:article, title: 'Custom Title', published: true)

# Using scope
article = create(:article, scope: :core)
```

## Integration with Clean Architecture

The factory generator works seamlessly with other rider-kick generators:

```bash
# 1. Setup clean architecture
rails generate rider_kick:clean_arch --setup

# 2. Generate structure
rails generate rider_kick:structure Models::Article actor:owner

# 3. Generate scaffold
rails generate rider_kick:scaffold articles scope:dashboard

# 4. Generate factory
rails generate rider_kick:factory Models::Article scope:core
```

This creates a complete testing setup with:
- Domain structure (entities, use cases, repositories)
- RSpec tests (automatically generated)
- FactoryBot factories (for test data)

## Tips

1. **Always run after model creation:** Generate factories after your models are created and migrated to ensure all columns are detected.

2. **Scope organization:** Use scope parameter to organize factories by domain/feature:
   ```bash
   rails g rider_kick:factory Models::Article scope:blog
   rails g rider_kick:factory Models::Comment scope:blog
   rails g rider_kick:factory Models::User scope:auth
   ```

3. **Customize generated values:** After generation, you can customize the Faker methods:
   ```ruby
   FactoryBot.define do
     factory :article, class: 'Models::Article' do
       title { Faker::Book.title }  # Changed from Lorem.sentence
       published { true }             # Changed from random
     end
   end
   ```

4. **Add associations manually:** Since foreign keys are skipped, add associations manually:
   ```ruby
   FactoryBot.define do
     factory :article, class: 'Models::Article' do
       title { Faker::Lorem.sentence(word_count: 3) }
       
       # Add associations manually
       association :user, factory: :user
       association :category, factory: :category
     end
   end
   ```

## Troubleshooting

### Model Not Found Error

If you get a "Model not found" error:

```bash
Error: Model Models::Article not found. Make sure the model exists.
```

**Solution:** Ensure the model is created and migrated:

```bash
rails g model models/article title content:text
rails db:migrate
```

### Factory Not Loading

If FactoryBot doesn't find your factory:

**Solution:** Ensure `spec/support/factory_bot.rb` is configured correctly:

```ruby
# spec/support/factory_bot.rb
RSpec.configure do |config|
  config.include FactoryBot::Syntax::Methods
end
```

And your `rails_helper.rb` requires support files:

```ruby
# spec/rails_helper.rb
Dir[Rails.root.join('spec/support/**/*.rb')].sort.each { |f| require f }
```

## See Also

- [RSpec Generation Documentation](SPEC_GENERATION.md)
- [Main README](README.md)
- [Upgrade Guide](UPGRADE.md)

