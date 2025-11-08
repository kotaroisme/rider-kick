# List Repository Spec Enhancements

## Overview

Template RSpec untuk list repository telah ditingkatkan dengan comprehensive test coverage, termasuk search tests untuk `search_able` fields dan detailed pagination tests.

## New Features

### 1. Search Tests (Auto-generated from `search_able`)

Jika structure YAML memiliki `search_able` array, template akan auto-generate test untuk setiap field:

```yaml
# db/structures/articles_structure.yaml
search_able:
  - title
  - content
```

**Generated Tests:**

```ruby
context 'with search filters' do
  it 'filters by title', :aggregate_failures do
    matching_item = create(:article, title: 'SearchTerm123')
    non_matching_item = create(:article, title: 'DifferentValue')
    
    params[:search] = 'searchterm'
    result = repository.new(params: params).call

    expect(result[:response]).to be_present
    response_ids = result[:response].map { |item| item[:id] }
    expect(response_ids).to include(matching_item.id)
    expect(response_ids).not_to include(non_matching_item.id)
  end

  it 'filters by content', :aggregate_failures do
    # Similar test for content field
  end

  it 'performs case-insensitive search', :aggregate_failures do
    item = create(:article, title: 'UPPERCASE_VALUE')
    params[:search] = 'uppercase'
    result = repository.new(params: params).call

    response_ids = result[:response].map { |item| item[:id] }
    expect(response_ids).to include(item.id)
  end

  it 'returns empty result when no matches found' do
    params[:search] = 'NonExistentValue12345'
    result = repository.new(params: params).call

    expect(result[:response]).to be_empty
    expect(result[:meta][:count]).to eq(0)
  end
end
```

### 2. Pagination Tests

#### Page 3, Per Page 3 Test

```ruby
context 'with pagination' do
  before do
    create_list(:article, 10, account_id: params[:account_id])
  end

  it 'paginates correctly with page 3 and per_page 3', :aggregate_failures do
    params[:page] = 3
    params[:per_page] = 3
    
    result = repository.new(params: params).call

    expect(result[:response]).to be_present
    expect(result[:response].length).to eq(3)
    expect(result[:meta][:page]).to eq(3)
    expect(result[:meta][:per_page]).to eq(3)
    expect(result[:meta][:count]).to eq(10)
    expect(result[:meta][:pages]).to be_present
    expect(result[:meta][:pages]).to be >= 3
  end
end
```

#### Additional Pagination Tests

- ✅ Empty result for page beyond available pages
- ✅ Per_page parameter handling
- ✅ Verify pagy metadata (count, page, per_page, pages)

### 3. Enhanced Expectations

#### Response Structure Validation

```ruby
it 'returns paginated articles', :aggregate_failures do
  result = repository.new(params: params).call

  expect(result[:response]).to be_present
  expect(result[:response]).to be_an(Array)
  expect(result[:meta]).to be_present
  expect(result[:meta]).to be_a(Hash)
  expect(result[:meta][:count]).to be_present
  expect(result[:meta][:page]).to eq(1)
  expect(result[:meta][:per_page]).to eq(10)
end
```

#### Resource Owner Filter Verification

```ruby
context 'with resource owner filter' do
  it 'filters by resource owner', :aggregate_failures do
    result = repository.new(params: params).call

    expect(result[:response]).to be_present
    # Verify all returned items belong to the specified owner
    result[:response].each do |item|
      expect(item[:account_id]).to eq(params[:account_id])
    end
    expect(result[:meta][:count]).to eq(2)
  end
end
```

#### Sorting Verification

```ruby
it 'sorts by created_at descending by default', :aggregate_failures do
  result = repository.new(params: params).call

  # Verify descending order (newest first)
  timestamps = result[:response].map { |item| item[:created_at] }
  expect(timestamps).to eq(timestamps.sort.reverse)
end
```

### 4. Edge Case Testing

#### Empty State Handling

```ruby
context 'when no resources exist' do
  before do
    Models::Article.destroy_all
  end

  it 'returns empty response with zero count', :aggregate_failures do
    result = repository.new(params: params).call

    expect(result[:response]).to be_an(Array)
    expect(result[:response]).to be_empty
    expect(result[:meta][:count]).to eq(0)
    expect(result[:meta][:page]).to eq(1)
    expect(result[:meta][:per_page]).to eq(10)
  end
end
```

## Complete Test Coverage

### Test Categories

1. **Basic List Tests**
   - Returns paginated results
   - Response structure validation
   - Meta pagination data
   - Correct items per page

2. **Search Tests** (if `search_able` defined)
   - Filter by each searchable field
   - Case-insensitive search
   - Empty result handling

3. **Pagination Tests**
   - Page 3, per_page 3 (as requested)
   - Beyond available pages
   - Per_page parameter

4. **Resource Owner Tests** (if `resource_owner_id` present)
   - Filter by resource owner
   - Count verification
   - Ownership verification

5. **Sorting Tests**
   - Default descending order
   - Custom sorting
   - Order verification

6. **Edge Cases**
   - Empty state
   - No matches found
   - Beyond pages

## Example: Complete Generated Spec

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

        expect(result[:response]).to be_present
        expect(result[:response]).to be_an(Array)
        expect(result[:meta]).to be_present
        expect(result[:meta]).to be_a(Hash)
        expect(result[:meta][:count]).to be_present
        expect(result[:meta][:page]).to eq(1)
        expect(result[:meta][:per_page]).to eq(10)
      end

      it 'returns correct number of items per page' do
        result = repository.new(params: params).call
        expect(result[:response].length).to be <= params[:per_page]
      end
    end

    context 'with search filters' do
      it 'filters by title', :aggregate_failures do
        matching_item = create(:article, account_id: params[:account_id], title: 'SearchTerm123')
        non_matching_item = create(:article, account_id: params[:account_id], title: 'DifferentValue')
        
        params[:search] = 'searchterm'
        result = repository.new(params: params).call

        expect(result[:response]).to be_present
        response_ids = result[:response].map { |item| item[:id] }
        expect(response_ids).to include(matching_item.id)
        expect(response_ids).not_to include(non_matching_item.id)
      end

      it 'performs case-insensitive search', :aggregate_failures do
        item = create(:article, account_id: params[:account_id], title: 'UPPERCASE_VALUE')
        params[:search] = 'uppercase'
        result = repository.new(params: params).call

        response_ids = result[:response].map { |item| item[:id] }
        expect(response_ids).to include(item.id)
      end

      it 'returns empty result when no matches found' do
        params[:search] = 'NonExistentValue12345'
        result = repository.new(params: params).call

        expect(result[:response]).to be_empty
        expect(result[:meta][:count]).to eq(0)
      end
    end

    context 'with resource owner filter' do
      let(:other_owner_id) { SecureRandom.uuid }

      before do
        create_list(:article, 2, account_id: params[:account_id])
        create_list(:article, 2, account_id: other_owner_id)
      end

      it 'filters by resource owner', :aggregate_failures do
        result = repository.new(params: params).call

        expect(result[:response]).to be_present
        result[:response].each do |item|
          expect(item[:account_id]).to eq(params[:account_id])
        end
        expect(result[:meta][:count]).to eq(2)
      end
    end

    context 'with pagination' do
      before do
        create_list(:article, 10, account_id: params[:account_id])
      end

      it 'paginates correctly with page 3 and per_page 3', :aggregate_failures do
        params[:page] = 3
        params[:per_page] = 3
        
        result = repository.new(params: params).call

        expect(result[:response].length).to eq(3)
        expect(result[:meta][:page]).to eq(3)
        expect(result[:meta][:per_page]).to eq(3)
        expect(result[:meta][:count]).to eq(10)
        expect(result[:meta][:pages]).to be >= 3
      end

      it 'returns empty array for page beyond available pages' do
        params[:page] = 999
        result = repository.new(params: params).call

        expect(result[:response]).to be_empty
        expect(result[:meta][:count]).to eq(10)
      end
    end

    context 'with sorting' do
      it 'sorts by created_at descending by default', :aggregate_failures do
        result = repository.new(params: params).call

        timestamps = result[:response].map { |item| item[:created_at] }
        expect(timestamps).to eq(timestamps.sort.reverse)
      end
    end

    context 'when no resources exist' do
      before do
        Models::Article.destroy_all
      end

      it 'returns empty response with zero count', :aggregate_failures do
        result = repository.new(params: params).call

        expect(result[:response]).to be_empty
        expect(result[:meta][:count]).to eq(0)
      end
    end
  end
end
```

## Benefits

1. **Comprehensive Coverage** - Tests cover all major scenarios
2. **Auto-generated** - Search tests automatically generated from `search_able`
3. **Quality Assurance** - Multiple assertions ensure correctness
4. **Edge Case Handling** - Tests handle empty states and error cases
5. **Maintainable** - Clear test structure and descriptions
6. **Realistic** - Tests use actual factory data and verify real behavior

## Usage

### Generate with Search Tests

```bash
# Structure YAML with search_able
# db/structures/articles_structure.yaml
search_able:
  - title
  - content

# Generate scaffold
rails generate rider_kick:scaffold articles scope:dashboard

# Generated spec will include search tests automatically
```

### Without Search Tests

If `search_able` is empty or not defined, template will generate placeholder:

```ruby
context 'with search filters' do
  # Add search filter tests here if needed
end
```

## See Also

- [List Spec Format Documentation](LIST_SPEC_FORMAT.md)
- [RSpec Generation Guide](SPEC_GENERATION.md)
- [Main README](README.md)


