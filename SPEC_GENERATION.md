# RSpec Generation Documentation

## Overview

Gem RiderKick sekarang secara otomatis men-generate RSpec files untuk setiap code file yang di-generate. Spec files akan ditempatkan sejajar dengan code files mereka di direktori yang sama.

## File yang Di-generate

Ketika Anda menjalankan `rider_kick:scaffold` generator, generator akan men-generate:

### Code Files (sudah ada):
- Use Cases: `app/domains/core/use_cases/<scope>/<resource>/<actor>_<action>_<model>.rb`
- Repositories: `app/domains/core/repositories/<resource>/<action>_<model>.rb`
- Builder: `app/domains/core/builders/<model>.rb`
- Entity: `app/domains/core/entities/<model>.rb`

### Spec Files (BARU):
- Use Case Specs: `app/domains/core/use_cases/<scope>/<resource>/<actor>_<action>_<model>_spec.rb`
- Repository Specs: `app/domains/core/repositories/<resource>/<action>_<model>_spec.rb`
- Builder Spec: `app/domains/core/builders/<model>_spec.rb`
- Entity Spec: `app/domains/core/entities/<model>_spec.rb`

## Contoh Penggunaan

### 1. Generate Structure
```bash
bin/rails generate rider_kick:structure Models::Product actor:user uploaders:image,documents
```

### 2. Generate Scaffold (dengan RSpec)
```bash
bin/rails generate rider_kick:scaffold products
```

### Output
Generator akan men-generate file-file berikut:

**Code Files:**
```
app/domains/core/
├── use_cases/products/
│   ├── user_create_product.rb
│   ├── user_update_product.rb
│   ├── user_list_product.rb
│   ├── user_destroy_product.rb
│   └── user_fetch_product_by_id.rb
├── repositories/products/
│   ├── create_product.rb
│   ├── update_product.rb
│   ├── list_product.rb
│   ├── destroy_product.rb
│   └── fetch_product_by_id.rb
├── builders/
│   └── product.rb
└── entities/
    └── product.rb
```

**Spec Files:**
```
app/domains/core/
├── use_cases/products/
│   ├── user_create_product_spec.rb
│   ├── user_update_product_spec.rb
│   ├── user_list_product_spec.rb
│   ├── user_destroy_product_spec.rb
│   └── user_fetch_product_by_id_spec.rb
├── repositories/products/
│   ├── create_product_spec.rb
│   ├── update_product_spec.rb
│   ├── list_product_spec.rb
│   ├── destroy_product_spec.rb
│   └── fetch_product_by_id_spec.rb
├── builders/
│   └── product_spec.rb
└── entities/
    └── product_spec.rb
```

## Konten Spec Files

### Use Case Specs
Spec files untuk use cases mencakup test untuk:
- ✅ Parameter validation
- ✅ Success case
- ✅ Failure case (validation errors)
- ✅ Repository failure
- ✅ Resource owner ID (jika didefinisikan)

### Repository Specs
Spec files untuk repositories mencakup test untuk:
- ✅ Success case
- ✅ Failure case (database errors)
- ✅ Not found case
- ✅ Resource owner filtering (jika didefinisikan)
- ✅ Uploaders (jika didefinisikan)
- ✅ Pagination (untuk list)
- ✅ Filtering (untuk list)

### Builder Specs
Spec files untuk builders mencakup test untuk:
- ✅ Build entity from model
- ✅ Handle uploaders (single & multiple)
- ✅ Handle minimal data
- ✅ URL generation untuk uploaders
- ✅ Test `acts_as_builder_for_entity` - memastikan entity yang di-build benar
- ✅ Test `attributes_for_entity` method (jika ada uploaders)
- ✅ Verify all entity attributes exist (keys must exist, values can be nil for optional)
- ✅ Source of truth adalah entity definition

**Note:** Builder specs menggunakan `ClassStubber::Model` untuk membuat test data yang lebih sederhana dan mudah dibaca, daripada menggunakan `instance_double` dengan banyak `allow().to receive()` calls.

**Type-aware Values:** Generator secara otomatis menggunakan nilai yang sesuai dengan tipe field:
- `datetime`, `timestamp`, `time` → `Time.current`
- `date` → `Date.current`
- `boolean` → `true` / `false`
- `integer`, `bigint` → `123`
- `decimal`, `float` → `123.45`
- String dan tipe lainnya → `'field_name_value'`

**Entity Attribute Coverage:** Spec memastikan semua attribute yang didefinisikan di entity ter-cover:
- Test bahwa entity punya semua attribute (via `respond_to?`)
- Test bahwa entity hash punya semua keys (via `have_key`)
- Optional attributes tetap harus punya key (value boleh nil)

### Entity Specs
Spec files untuk entities mencakup test untuk:
- ✅ Structure validation
- ✅ Attribute presence
- ✅ Instantiation dengan valid attributes
- ✅ Key transformation (string to symbol)
- ✅ Optional attributes
- ✅ Required attributes validation
- ✅ Immutability

## Fitur Spec

### 1. Support untuk Resource Owner
Jika structure YAML Anda mendefinisikan `resource_owner_id`, spec files akan otomatis include test untuk multi-tenancy:

```ruby
# In spec file
let(:valid_params) do
  {
    account_id: 'account-123',  # resource_owner_id
    name: 'Product Name'
  }
end
```

### 2. Support untuk Uploaders
Spec files otomatis handle single dan multiple file uploaders menggunakan `ClassStubber::ActiveStorageAttachment`:

```ruby
# Setup model dengan uploader
let(:article) do
  ClassStubber::Model.new(
    'id' => 'test-id-123',
    'title' => 'Article Title',
    'published_at' => Time.current,        # datetime fields use Time
    'price' => 123.45,                      # decimal fields use numbers
    'is_active' => true,                    # boolean fields use true/false
    'image' => ClassStubber::ActiveStorageAttachment.new_single('http://example.com/image.jpg'),
    'documents' => ClassStubber::ActiveStorageAttachment.new_multiple([
      'http://example.com/doc1.pdf',
      'http://example.com/doc2.pdf'
    ])
  )
end

# Single uploader test
context 'with image attached' do
  it 'includes image URL' do
    entity = builder.build
    expect(entity.image_url).to eq('http://example.com/image.jpg')
  end
end

# Multiple uploaders test
context 'with documents attached' do
  it 'includes documents URLs' do
    entity = builder.build
    expect(entity.documents_urls).to be_an(Array)
    expect(entity.documents_urls.size).to eq(2)
  end
end
```

### 3. Support untuk Pagination
List repository specs include pagination testing:

```ruby
it 'returns paginated products' do
  result = repository.call(params: params)
  expect(result[:data]).to be_present
  expect(result[:pagy]).to be_a(Pagy)
end
```

### 4. Support untuk Search Filters
List repository specs include filtering tests jika `search_able` didefinisikan di structure:

```ruby
context 'with search filters' do
  it 'filters by name' do
    params[:name] = 'search_term'
    result = repository.call(params: params)
    expect(result[:data]).to be_present
  end
end
```

## Menjalankan Specs

### Run semua specs
```bash
bundle exec rspec
```

### Run spec untuk specific file
```bash
# Use case spec
bundle exec rspec app/domains/core/use_cases/products/user_create_product_spec.rb

# Repository spec
bundle exec rspec app/domains/core/repositories/products/create_product_spec.rb

# Builder spec
bundle exec rspec app/domains/core/builders/product_spec.rb

# Entity spec
bundle exec rspec app/domains/core/entities/product_spec.rb
```

### Run spec untuk specific directory
```bash
# All use case specs for products
bundle exec rspec app/domains/core/use_cases/products/

# All repository specs
bundle exec rspec app/domains/core/repositories/

# All builder & entity specs
bundle exec rspec app/domains/core/builders/
bundle exec rspec app/domains/core/entities/
```

## Customization

Jika Anda perlu mengcustomize spec templates, edit file-file berikut:

### Use Case Spec Templates
- `lib/generators/rider_kick/templates/domains/core/use_cases/create_spec.rb.tt`
- `lib/generators/rider_kick/templates/domains/core/use_cases/update_spec.rb.tt`
- `lib/generators/rider_kick/templates/domains/core/use_cases/list_spec.rb.tt`
- `lib/generators/rider_kick/templates/domains/core/use_cases/destroy_spec.rb.tt`
- `lib/generators/rider_kick/templates/domains/core/use_cases/fetch_by_id_spec.rb.tt`

### Repository Spec Templates
- `lib/generators/rider_kick/templates/domains/core/repositories/create_spec.rb.tt`
- `lib/generators/rider_kick/templates/domains/core/repositories/update_spec.rb.tt`
- `lib/generators/rider_kick/templates/domains/core/repositories/list_spec.rb.tt`
- `lib/generators/rider_kick/templates/domains/core/repositories/destroy_spec.rb.tt`
- `lib/generators/rider_kick/templates/domains/core/repositories/fetch_by_id_spec.rb.tt`

### Builder & Entity Spec Templates
- `lib/generators/rider_kick/templates/domains/core/builders/builder_spec.rb.tt`
- `lib/generators/rider_kick/templates/domains/core/entities/entity_spec.rb.tt`

## Best Practices

1. **Regenerate Specs:** Jika Anda mengubah structure YAML dan regenerate scaffold, spec files akan di-update otomatis.

2. **Custom Tests:** Setelah generate, Anda bisa menambahkan custom tests ke spec files.

3. **Factory Bot:** Gunakan FactoryBot untuk membuat test data yang lebih realistis.

4. **Test Coverage:** Pastikan semua edge cases ter-cover dengan menambahkan custom tests.

5. **Idempotency:** Generator bersifat idempoten - menjalankan ulang tidak akan menduplikasi konten.

## Setup Requirements

Generator RSpec membutuhkan `ClassStubber` helper yang otomatis di-generate saat Anda menjalankan:

```bash
bin/rails generate rider_kick:clean_arch --setup
```

Helper ini akan di-generate di:
- `spec/support/class_stubber.rb` - Helper untuk mock models dan attachments
- `spec/rails_helper.rb` - Sudah ter-configure untuk include ClassStubber

Jika Anda sudah setup sebelumnya tanpa ClassStubber, Anda bisa:

1. **Copy manual dari template**:
```bash
# Copy class_stubber.rb dari gem ke project
cp $(bundle show rider-kick)/lib/generators/rider_kick/templates/spec/support/class_stubber.rb spec/support/
```

2. **Atau tambahkan manual ke rails_helper.rb**:
```ruby
# spec/rails_helper.rb
Dir[Rails.root.join('spec', 'support', '**', '*.rb')].sort.each { |f| require f }

RSpec.configure do |config|
  # ... existing config ...
  config.include ClassStubber
end
```

## Troubleshooting

### Error: uninitialized constant ClassStubber
**Penyebab**: Helper ClassStubber belum ter-setup

**Solusi**:
1. Pastikan file `spec/support/class_stubber.rb` ada
2. Pastikan `spec/rails_helper.rb` meng-include ClassStubber
3. Jika tidak ada, copy dari template atau re-run setup:
```bash
bin/rails generate rider_kick:clean_arch --setup
```

### Error: has invalid type for :field_name violates constraints
**Contoh Error**:
```
Dry::Struct::Error: [Entity.new] #<ClassStubber::ActiveStorageAttachment...> 
has invalid type for :images violates constraints (type?(String, ...) failed)
```

**Penyebab**: Field uploader (seperti `images`) ada di `entity.db_attributes` di YAML, padahal seharusnya tidak.

**Solusi**:
Hapus uploader field dari `entity.db_attributes` di structure YAML file:

```yaml
# SALAH ❌
uploaders:
  - { name: 'images', type: 'multiple' }
entity:
  db_attributes:
    - title
    - body
    - images    # ← HAPUS INI!

# BENAR ✅
uploaders:
  - { name: 'images', type: 'multiple' }
entity:
  db_attributes:
    - title
    - body
    # images tidak perlu di sini, karena sudah di uploaders
```

Entity akan otomatis mendapat field `images_urls` (untuk multiple) atau `image_url` (untuk single) dari uploader configuration.

### Spec files tidak ter-generate
- Pastikan Anda sudah menjalankan `bin/rails generate rider_kick:clean_arch --setup`
- Pastikan structure YAML file valid
- Cek log generator untuk error messages

### Spec tests gagal
- Pastikan database test sudah di-setup: `RAILS_ENV=test bin/rails db:setup`
- Pastikan semua dependencies sudah ter-install: `bundle install`
- Cek apakah ada model atau factory yang belum didefinisikan
- Pastikan ClassStubber helper sudah ter-setup (lihat di atas)

### Custom spec templates tidak ter-apply
- Pastikan file template berada di lokasi yang benar
- Pastikan file template memiliki extension `.rb.tt`
- Regenerate scaffold untuk apply template baru

## Support

Jika Anda menemukan bug atau memiliki pertanyaan:
1. Cek dokumentasi di README.md
2. Cek issue tracker di GitHub
3. Buat issue baru dengan detail lengkap tentang masalah Anda

