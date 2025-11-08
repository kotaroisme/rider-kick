# Factory Generator - Quick Example

## Complete Workflow Example

### Step 1: Create a Rails Model

```bash
rails generate model models/article title:string content:text summary:text user_id:integer category_id:integer published:boolean views_count:integer
rails db:migrate
```

This creates a model with the following schema:

```ruby
# db/schema.rb
create_table "articles", force: :cascade do |t|
  t.string "title"
  t.text "content"
  t.text "summary"
  t.integer "user_id"
  t.integer "category_id"
  t.boolean "published"
  t.integer "views_count"
  t.datetime "created_at", null: false
  t.datetime "updated_at", null: false
end
```

### Step 2: Generate Factory

```bash
rails generate rider_kick:factory Models::Article scope:core
```

**Output:**
```
Using main app (no engine specified)
      create  spec/factories/core/article.rb
Factory created: spec/factories/core/article.rb
```

### Step 3: Generated Factory File

**File:** `spec/factories/core/article.rb`

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

**Notice:**
- ✅ `title` gets `Faker::Lorem.sentence` (smart detection for *title* fields)
- ✅ `content` gets `Faker::Lorem.paragraph` (smart detection for *content* fields)
- ✅ `summary` gets `Faker::Lorem.sentence` (text field)
- ✅ `published` gets `[true, false].sample` (boolean)
- ✅ `views_count` gets range-based number (smart detection for *count* fields)
- ❌ `user_id` skipped (foreign key)
- ❌ `category_id` skipped (foreign key)
- ❌ `created_at` skipped (timestamp)
- ❌ `updated_at` skipped (timestamp)
- ❌ `id` skipped (primary key)

### Step 4: Use in Tests

```ruby
# spec/domains/core/use_cases/articles/create_article_spec.rb
RSpec.describe 'CreateArticle' do
  it 'creates an article' do
    article = create(:article)
    
    expect(article.title).to be_present
    expect(article.content).to be_present
    expect(article.published).to be_in([true, false])
  end
  
  it 'creates article with custom attributes' do
    article = create(:article, title: 'Custom Title', published: true)
    
    expect(article.title).to eq('Custom Title')
    expect(article.published).to be true
  end
  
  it 'creates multiple articles' do
    articles = create_list(:article, 5)
    
    expect(articles.count).to eq(5)
  end
end
```

## Static Factory Example

### Generate Factory with Static Values

Instead of Faker calls, you can generate factories with pre-evaluated static values:

```bash
rails generate rider_kick:factory Models::Article scope:core --static
```

**Generated Static Factory:**

```ruby
FactoryBot.define do
  factory :article, class: 'Models::Article' do
    title { 'Sit voluptatem aut' }
    content { 'Quia et et. Quis ut quo. Aut voluptas id.' }
    summary { 'Earum rerum hic tenetur.' }
    published { true }
    views_count { 42 }
  end
end
```

**Benefits of Static Factories:**
- ✅ Consistent test data every time
- ✅ Easier to debug specific test cases
- ✅ Can be customized with real-world values
- ✅ Faster test execution (no Faker evaluation on each test)

**When to use static factories:**
- When testing specific business logic that requires exact values
- For debugging failing tests
- When you want to manually set realistic data
- For integration tests with specific scenarios

**Comparison:**

| Feature | Standard Factory | Static Factory (--static) |
|---------|------------------|---------------------------|
| Values | Random via Faker | Pre-generated static |
| Test Data | Different each run | Same every run |
| Debugging | Harder | Easier |
| Flexibility | High | Medium |
| Speed | Slightly slower | Slightly faster |
| Best For | Varied test scenarios | Specific test cases |
| **Time Fields** | `Time.zone.now` | `Time.zone.now` *(same)* |

## More Examples

### User Model

```bash
rails g model models/user email:string full_name:string phone_number:string age:integer city:string country:string bio:text
rails db:migrate
rails g rider_kick:factory Models::User scope:core
```

**Generated Factory:**

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

### Event Model (with DateTime fields)

```bash
rails g model models/event title:string description:text start_time:datetime end_time:datetime published_at:datetime
rails db:migrate
rails g rider_kick:factory Models::Event scope:core
```

**Generated Factory:**

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

**With --static flag:**

```bash
rails g rider_kick:factory Models::Event scope:core --static
```

```ruby
FactoryBot.define do
  factory :event, class: 'Models::Event' do
    title { 'Sit voluptatem aut' }
    description { 'Quia et et. Quis ut quo. Aut voluptas id.' }
    start_time { Time.zone.now }
    end_time { Time.zone.now }
    published_at { Time.zone.now }
  end
end
```

**Note:**
- All `datetime`, `timestamp`, and `time` fields use `Time.zone.now`
- This ensures timezone-aware timestamps
- **Important:** Time fields are NEVER evaluated to static values, even with `--static` flag
- Both standard and static modes use `Time.zone.now` for time fields
- This ensures tests always use current time and respect timezone settings

### Product Model

```bash
rails g model models/product name:string description:text price:decimal stock_count:integer sku_code:string available:boolean category_id:integer
rails db:migrate
rails g rider_kick:factory Models::Product scope:admin
```

**Generated Factory:**

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

## Adding Associations (Manual)

Since foreign keys are skipped, you can add associations manually:

```ruby
# spec/factories/core/article.rb
FactoryBot.define do
  factory :article, class: 'Models::Article' do
    title { Faker::Lorem.sentence(word_count: 3) }
    content { Faker::Lorem.paragraph(sentence_count: 3) }
    summary { Faker::Lorem.sentence }
    published { [true, false].sample }
    views_count { Faker::Number.between(from: 1, to: 100) }
    
    # Add associations manually
    association :user, factory: :user
    association :category, factory: :category
  end
end
```

Then use in tests:

```ruby
# Creates article with associated user and category
article = create(:article)
expect(article.user).to be_present
expect(article.category).to be_present

# Or create article with existing associations
user = create(:user)
category = create(:category)
article = create(:article, user: user, category: category)
```

## Complete Clean Architecture Workflow

```bash
# 1. Setup Clean Architecture
rails generate rider_kick:clean_arch --setup

# 2. Create model
rails g model models/article title:string content:text user_id:integer published:boolean
rails db:migrate

# 3. Generate structure YAML
rails generate rider_kick:structure Models::Article actor:owner

# 4. Generate scaffold (with auto specs)
rails generate rider_kick:scaffold articles scope:dashboard

# 5. Generate factory
rails generate rider_kick:factory Models::Article scope:core
```

**Result:** Complete setup with:
- ✅ Domain structure (entities, use cases, repositories, builders)
- ✅ Auto-generated RSpec specs for all components
- ✅ FactoryBot factory for test data
- ✅ Ready to write integration tests!

## Tips

1. **Run factory generation after migrations** to ensure all columns are detected
2. **Use scopes** to organize factories by domain: `scope:blog`, `scope:auth`, `scope:admin`
3. **Customize Faker methods** after generation if needed
4. **Add associations manually** for foreign key relationships
5. **Use traits** for common scenarios (optional, add manually)

## Next Steps

After generating factories, you can:
1. Run specs to verify everything works: `bundle exec rspec`
2. Customize Faker values in the generated factory files
3. Add associations and traits as needed
4. Write integration tests using the factories

Happy testing! 🎉

