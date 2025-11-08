# List Repository Spec Format

## Overview

Template RSpec untuk list repository telah diupdate mengikuti format yang lebih konsisten dan best practice.

## Format Baru

### Dengan Resource Owner ID

```ruby
# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Core::Repositories::Articles::ListArticle, type: :repository do
  describe '#call' do
    let(:params) do
      {
        account_id: SecureRandom.uuid,
        page: 1,
        per_page: 10
      }
    end

    let(:repository) { described_class }

    before do
      create_list(:article, 3, account_id: params[:account_id])
    end

    context 'when fetching list successfully' do
      it 'returns paginated articles', :aggregate_failures do
        result = repository.new(params: params).call

        expect(result[:data]).to be_present
        expect(result[:pagy]).to be_a(Pagy)
      end
    end

    context 'with search filters' do
      it 'filters by title', :aggregate_failures do
        params[:title] = 'search_term'
        
        result = repository.new(params: params).call

        expect(result[:data]).to be_present
        expect(result[:pagy]).to be_a(Pagy)
      end
    end

    context 'with resource owner filter' do
      let(:resource_owner) { double('resource_owner', id: 'owner-123') }

      it 'filters by resource owner' do
        result = repository.new(params: params).call

        expect(result[:data]).to be_present
      end
    end

    context 'with sorting' do
      it 'sorts by specified column' do
        params[:sort_by] = 'created_at'
        params[:sort_dir] = 'asc'

        result = repository.new(params: params).call

        expect(result[:data]).to be_present
      end
    end
  end
end
```

### Tanpa Resource Owner ID

```ruby
# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Core::Repositories::Products::ListProduct, type: :repository do
  describe '#call' do
    let(:params) do
      {
        page: 1,
        per_page: 10
      }
    end

    let(:repository) { described_class }

    before do
      create_list(:product, 3)
    end

    context 'when fetching list successfully' do
      it 'returns paginated products', :aggregate_failures do
        result = repository.new(params: params).call

        expect(result[:data]).to be_present
        expect(result[:pagy]).to be_a(Pagy)
      end
    end

    context 'with search filters' do
      # Add search filter tests here if needed
    end

    context 'with sorting' do
      it 'sorts by specified column' do
        params[:sort_by] = 'created_at'
        params[:sort_dir] = 'asc'

        result = repository.new(params: params).call

        expect(result[:data]).to be_present
      end
    end
  end
end
```

## Key Changes

### 1. Repository Instantiation

**Sebelum:**
```ruby
let(:repository) { described_class.new }

# Usage
result = repository.call(params: params)
```

**Sesudah:**
```ruby
let(:repository) { described_class }

# Usage
result = repository.new(params: params).call
```

**Alasan:**
- Lebih fleksibel untuk testing dengan different initialization
- Memisahkan instantiation dari test setup
- Pattern yang lebih umum di RSpec

### 2. Data Setup

**Sebelum:**
```ruby
let(:articles) { create_list(:article, 3) }

before do
  articles
end
```

**Sesudah:**
```ruby
before do
  create_list(:article, 3, account_id: params[:account_id])
end
```

**Alasan:**
- Lebih direct dan clear
- Menghindari unnecessary `let` variable
- Langsung meng-associate dengan params

### 3. Resource Owner ID di Params

**Sebelum:**
```ruby
let(:params) do
  {
    page: 1,
    per_page: 10
  }
end
```

**Sesudah (jika ada resource_owner_id):**
```ruby
let(:params) do
  {
    account_id: SecureRandom.uuid,
    page: 1,
    per_page: 10
  }
end
```

**Alasan:**
- Params sudah include resource owner ID
- Data yang di-create langsung ter-associate
- Lebih realistic untuk actual usage

### 4. Search Filter Tests

**Sebelum:**
```ruby
context 'with search filters' do
  # (conditional generation per filter)
end
```

**Sesudah:**
```ruby
context 'with search filters' do
  it 'filters by title', :aggregate_failures do
    params[:title] = 'search_term'
    
    result = repository.new(params: params).call

    expect(result[:data]).to be_present
    expect(result[:pagy]).to be_a(Pagy)
  end
end
```

**Alasan:**
- Menggunakan `repository.new(params: params).call` pattern
- Consistent dengan format baru

## Template Variables

Template menggunakan ERB variables berikut:

- `<%= @scope_class %>` - Scope class name (e.g., Articles)
- `<%= @repository_class %>` - Repository class name (e.g., ListArticle)
- `<%= @variable_subject %>` - Factory name (e.g., article)
- `<%= @scope_path %>` - Scope path (e.g., articles)
- `<%= @resource_owner_id %>` - Resource owner ID field (e.g., account_id)
- `<%= @repository_list_filters %>` - Array of filter definitions

## Example Generation

### YAML Structure File

```yaml
model: Models::Article
resource_name: article
actor: owner
resource_owner_id: account_id
search_able:
  - title
  - content
domains:
  action_list:
    use_case:
      contract: []
    repository:
      filters:
        - "{ field: 'title', type: 'search' }"
        - "{ field: 'content', type: 'search' }"
```

### Generate Command

```bash
rails generate rider_kick:scaffold articles scope:dashboard
```

### Generated Spec

The template will generate a spec file at:
`app/domains/core/repositories/articles/list_article_spec.rb`

With comprehensive test coverage:

#### 1. Basic List Tests
- ✅ Returns paginated results
- ✅ Response structure validation (Array, Hash)
- ✅ Meta pagination data verification
- ✅ Correct number of items per page

#### 2. Search Tests (if `search_able` defined)
- ✅ Test for each searchable field
  - Creates matching and non-matching items
  - Verifies matching items are included
  - Verifies non-matching items are excluded
- ✅ Case-insensitive search test
- ✅ Empty result when no matches found

#### 3. Pagination Tests
- ✅ **Page 3, per_page 3** (as requested)
  - Creates 10 items
  - Tests page 3 with 3 items per page
  - Verifies correct count, page, per_page, and pages
- ✅ Empty result for page beyond available pages
- ✅ Per_page parameter handling

#### 4. Resource Owner Filter Tests (if `resource_owner_id` present)
- ✅ Filters by resource owner
- ✅ Verifies all returned items belong to specified owner
- ✅ Count verification

#### 5. Sorting Tests
- ✅ Default sorting (created_at descending)
- ✅ Custom sorting (sort_by and sort_dir)
- ✅ Verifies order correctness

#### 6. Edge Cases
- ✅ Empty state handling (no resources exist)
- ✅ Proper error handling

## Benefits

1. **Consistency** - All list specs follow same pattern
2. **Clarity** - Clear separation of concerns
3. **Flexibility** - Easy to modify and extend
4. **Realistic** - Matches actual repository usage
5. **Testable** - Properly tests all scenarios

## Migration Guide

If you have existing specs in old format, update them:

1. Change repository instantiation:
   ```ruby
   # Old
   let(:repository) { described_class.new }
   result = repository.call(params: params)
   
   # New
   let(:repository) { described_class }
   result = repository.new(params: params).call
   ```

2. Add resource_owner_id to params (if applicable):
   ```ruby
   let(:params) do
     {
       account_id: SecureRandom.uuid,  # Add this
       page: 1,
       per_page: 10
     }
   end
   ```

3. Update data setup:
   ```ruby
   # Old
   let(:articles) { create_list(:article, 3) }
   before { articles }
   
   # New
   before do
     create_list(:article, 3, account_id: params[:account_id])
   end
   ```

4. Update all repository calls:
   ```ruby
   # Old
   repository.call(params: params)
   
   # New
   repository.new(params: params).call
   ```

## See Also

- [Main README](README.md)
- [RSpec Generation Documentation](SPEC_GENERATION.md)
- [Scaffold Generator](lib/generators/rider_kick/scaffold_generator.rb)

