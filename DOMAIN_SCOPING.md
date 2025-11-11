# Domain Scoping dengan --domain Option

## Overview

RiderKick sekarang mendukung **domain scoping** dengan `--domain` option, memungkinkan Anda mengorganisir domain files ke dalam scope yang berbeda berdasarkan konteks bisnis aplikasi Anda.

## Fitur Utama

- **Domain Scoping**: Organize domain files ke dalam folder terpisah (core/, admin/, api/v1/, dll.)
- **Engine Support**: Generate domain files dalam Rails engines dengan path models yang benar
- **Enhanced Model Specs**: Model specs dengan ekspektasi type kolom database dan Active Storage
- **Consistent File Placement**: Model specs ditempatkan sejajar dengan model files
- **Backward Compatible**: Domain default `core/` tetap bekerja tanpa perubahan

## Cara Penggunaan

### 1. Setup dengan Domain Default

```bash
# Domain default (core/)
bin/rails generate rider_kick:clean_arch --setup
```

### 2. Setup dengan Domain Khusus

```bash
# Admin domain
bin/rails generate rider_kick:clean_arch --setup --domain admin/

# API v1 domain
bin/rails generate rider_kick:clean_arch --setup --domain api/v1/

# Mobile domain
bin/rails generate rider_kick:clean_arch --setup --domain mobile/
```

### 3. Setup dalam Rails Engine

```bash
# Engine dengan domain default (akan menggunakan engine name sebagai domain)
bin/rails generate rider_kick:clean_arch --setup --engine MyEngine

# Engine dengan domain khusus
bin/rails generate rider_kick:clean_arch --setup --engine MyEngine --domain admin/
```

## Struktur File yang Dihasilkan

### Main Application

#### Domain Default (core/)
```text
app/
  domains/
    core/           # --domain core/ (default)
      entities/
        user.rb
      builders/
        user.rb
      repositories/
        users/
          create_user.rb
          list_user.rb
          ...
      use_cases/
        users/
          user_create_user.rb
          user_list_user.rb
          ...
      utils/
```

#### Multiple Domains
```text
app/
  domains/
    core/           # Domain utama
      entities/
      builders/
      repositories/
      use_cases/
      utils/
    admin/          # --domain admin/
      entities/
      builders/
      repositories/
      use_cases/
      utils/
    api/
      v1/           # --domain api/v1/
        entities/
        builders/
        repositories/
        use_cases/
        utils/
```

### Rails Engine

```text
engines/
  my_engine/
    app/
      domains/
        my_engine/        # --engine MyEngine (scope: my_engine/)
          entities/
          builders/
          repositories/
          use_cases/
          utils/
        my_engine/        # --engine MyEngine --domain admin/ (scope: my_engine/admin/)
          admin/
            entities/
            builders/
            repositories/
            use_cases/
            utils/
      models/
        my_engine/        # Engine models directory
          application_record.rb
          models/         # Engine models subdirectory
            models.rb
            company.rb    # Model: Models::MyEngine::Company
            company_spec.rb # Model spec with column type expectations
```

### Model Specs

RiderKick menghasilkan model specs yang comprehensive dengan ekspektasi untuk:

#### 1. Database Column Types
```ruby
describe 'database columns' do
  it 'has id column' do
    expect(Models::Company.column_names).to include('id')
  end

  it 'has id column of type uuid' do
    column = Models::Company.columns.find { |c| c.name == 'id' }
    expect(column&.type).to eq(:uuid)
  end

  it 'has name column of type string' do
    column = Models::Company.columns.find { |c| c.name == 'name' }
    expect(column&.type).to eq(:string)
  end
end
```

#### 2. Active Storage Attachments
```ruby
describe 'Active Storage attachments', :aggregate_failures do
  it 'has one logo attached' do
    expect(Models::Company.new.logo).to be_an_instance_of(ActiveStorage::Attached::One)
  end

  it 'can attach logo' do
    company = Models::Company.new
    company.logo.attach(
      io: StringIO.new('test'),
      filename: 'logo.jpg',
      content_type: 'image/jpeg'
    )
    expect(company.logo).to be_attached
  end
end
```

#### 3. Enum Definitions
```ruby
describe 'enums' do
  it { is_expected.to define_enum_for(:status).with_values(['active', 'inactive', 'pending']) }
end
```

## Contoh Lengkap Workflow

### Skenario: Aplikasi E-commerce dengan Multiple Domains

```bash
# 1. Setup domain utama (core)
rails new my_ecommerce -d=postgresql -T --skip-javascript
cd my_ecommerce
bundle add rider-kick
bin/rails generate rider_kick:clean_arch --setup --domain core/

# 2. Setup domain admin
bin/rails generate rider_kick:clean_arch --setup --domain admin/

# 3. Setup domain API v1
bin/rails generate rider_kick:clean_arch --setup --domain api/v1/

# 4. Buat model
rails g model models/product name price:decimal stock:integer category_id:integer
rails g model models/category name description:text
rails g model models/user email name role
rails db:migrate

# 5. Generate structure untuk products (core domain)
bin/rails generate rider_kick:structure Models::Product actor:user scope:dashboard
bin/rails generate rider_kick:structure Models::Category actor:admin scope:management

# 6. Generate scaffold dengan domain berbeda
bin/rails generate rider_kick:scaffold products scope:dashboard --domain core/
bin/rails generate rider_kick:scaffold categories scope:management --domain admin/
bin/rails generate rider_kick:scaffold products --domain api/v1/
```

### Hasil Struktur:

```text
app/
  domains/
    core/                           # Domain utama
      entities/
        product.rb
        category.rb
      builders/
        product.rb
        category.rb
      repositories/
        products/
          create_product.rb
          list_product.rb
          update_product.rb
          destroy_product.rb
          fetch_product_by_id.rb
        categories/
          create_category.rb
          list_category.rb
          ...
      use_cases/
        products/
          user_create_product.rb
          user_list_product.rb
          user_update_product.rb
          user_destroy_product.rb
          user_fetch_product_by_id.rb
        categories/
          admin_create_category.rb
          admin_list_category.rb
          ...
      utils/

    admin/                          # Domain admin
      entities/
        category.rb
      builders/
        category.rb
      repositories/
        categories/
          create_category.rb
          list_category.rb
          ...
      use_cases/
        categories/
          admin_create_category.rb
          admin_list_category.rb
          ...
      utils/

    api/
      v1/                           # Domain API
        entities/
          product.rb
        builders/
          product.rb
        repositories/
          products/
            create_product.rb
            list_product.rb
            ...
        use_cases/
          products/
            create_product.rb      # API biasanya tanpa actor prefix
            list_product.rb
            ...
        utils/
```

## Generator Commands dengan Domain

### Clean Architecture Setup

```bash
# Main app - domain default
rails generate rider_kick:clean_arch --setup

# Main app - domain khusus
rails generate rider_kick:clean_arch --setup --domain admin/

# Engine - domain default
rails generate rider_kick:clean_arch --setup --engine MyEngine

# Engine - domain khusus (akan menggunakan scope: my_engine/mobile/)
rails generate rider_kick:clean_arch --setup --engine MyEngine --domain mobile/
```

### Structure Generation

```bash
# Structure dengan domain default
rails generate rider_kick:structure Models::Product actor:user resource_owner:account resource_owner_id:account_id

# Structure dengan domain khusus
rails generate rider_kick:structure Models::Product actor:admin resource_owner:account resource_owner_id:account_id --domain admin/

# Structure dengan engine dan domain
rails generate rider_kick:structure Models::OrderEngine::Order actor:user resource_owner:account resource_owner_id:account_id --engine OrderEngine --domain fulfillment/
```

### Scaffold Generation

```bash
# Scaffold dengan domain default
rails generate rider_kick:scaffold products scope:dashboard

# Scaffold dengan domain khusus
rails generate rider_kick:scaffold products scope:dashboard --domain admin/

# Scaffold dalam engine
rails generate rider_kick:scaffold products --engine OrderEngine --domain fulfillment/
```
companies
### Structure Generation

```bash
# Structure dengan domain default
rails generate rider_kick:structure Models::Product actor:user resource_owner:account resource_owner_id:account_id

# Structure dengan domain khusus
rails generate rider_kick:structure Models::Product actor:admin resource_owner:account resource_owner_id:account_id --domain admin/

# Structure dalam Rails engine
rails generate rider_kick:structure Models::OrderEngine::Order actor:user resource_owner:account resource_owner_id:account_id --engine OrderEngine --domain fulfillment/
```

### Factory Generation

```bash
# Factory dengan domain default
rails generate rider_kick:factory Models::Product scope:core

# Factory dengan domain khusus (jika diperlukan)
rails generate rider_kick:factory Models::Product scope:admin
```

## Best Practices

### 1. Domain Naming Conventions

- **`core/`**: Domain utama aplikasi, business logic utama
- **`admin/`**: Domain untuk fitur admin/management
- **`api/v1/`**: Domain untuk API versioning
- **`mobile/`**: Domain untuk mobile-specific logic
- **`reporting/`**: Domain untuk laporan dan analytics
- **`fulfillment/`**: Domain untuk order fulfillment logic

### 2. Ketika Menggunakan Domain Scoping

#### Gunakan untuk:
- **Large applications** dengan banyak domain logic
- **API versioning** (api/v1/, api/v2/, dll.)
- **Multi-tenant applications** dengan domain berbeda per tenant
- **Microservices architecture** dalam satu monolith
- **Feature flags** atau experimental features

#### Jangan gunakan untuk:
- **Small applications** - gunakan domain default `core/`
- **Simple CRUD operations** - cukup gunakan domain default
- **Shared utilities** - gunakan `core/utils/`

### 3. Engine vs Domain

- **Rails Engine**: Untuk mengelompokkan related functionality yang bisa di-share antar aplikasi
- **Domain**: Untuk mengelompokkan related business logic dalam satu aplikasi/engine

```bash
# Engine dengan multiple domains (akan menggunakan scope yang di-prefix dengan engine name)
rails generate rider_kick:clean_arch --setup --engine OrderEngine --domain core/
rails generate rider_kick:clean_arch --setup --engine OrderEngine --domain fulfillment/
```

### 4. File Organization Tips

```ruby
# app/domains/core/use_cases/products/user_create_product.rb
module Core::UseCases::Products::UserCreateProduct
  # Business logic untuk create product di domain core
end

# app/domains/admin/use_cases/products/admin_update_product.rb
module Admin::UseCases::Products::AdminUpdateProduct
  # Business logic untuk admin update product
end

# app/domains/api/v1/use_cases/products/create_product.rb
module Api::V1::UseCases::Products::CreateProduct
  # API logic untuk create product (biasanya tanpa actor prefix)
end
```

## Migration dari Domain Default

Jika Anda sudah menggunakan RiderKick dan ingin migrate ke domain scoping:

### Step 1: Backup

```bash
# Backup existing domain files
cp -r app/domains/core app/domains/core_backup
```

### Step 2: Setup Domain Baru

```bash
# Setup domain baru
bin/rails generate rider_kick:clean_arch --setup --domain admin/
```

### Step 3: Move Files (jika diperlukan)

```bash
# Move admin-related files ke domain admin
mkdir -p app/domains/admin
mv app/domains/core/use_cases/admin_* app/domains/admin/use_cases/ 2>/dev/null || true
mv app/domains/core/repositories/admin_* app/domains/admin/repositories/ 2>/dev/null || true
# ... move other admin files
```

### Step 4: Update Code References

Update semua `require` statements dan module references dari `Core::` ke `Admin::` untuk files yang dipindah.

## Troubleshooting

### Error: Domain path tidak ditemukan

```bash
# Pastikan domain sudah di-setup
bin/rails generate rider_kick:clean_arch --setup --domain admin/

# Atau check existing domains
ls app/domains/
```

### Error: Engine domain path salah

```bash
# Untuk engine, pastikan engine name benar
bin/rails generate rider_kick:scaffold products --engine MyEngine --domain core/

# Check engine structure
ls engines/my_engine/app/domains/
```

### Error: Duplicate module names

Jika Anda punya module dengan nama sama di domain berbeda, pastikan namespacing benar:

```ruby
# app/domains/core/entities/product.rb
module Core::Entities::Product
end

# app/domains/admin/entities/product.rb
module Admin::Entities::Product
end
```

## FAQ

### Q: Apakah saya harus menggunakan domain scoping?

**A:** Tidak. Domain default `core/` masih fully supported. Gunakan domain scoping hanya jika aplikasi Anda kompleks dan membutuhkan organisasi yang lebih baik.

### Q: Bisakah saya mix domain default dan custom domains?

**A:** Ya! Anda bisa punya `app/domains/core/` sebagai domain utama dan `app/domains/admin/` untuk admin functionality.

### Q: Bagaimana dengan RSpec files?

**A:** RSpec files akan di-generate di path yang sama dengan code files mereka:
- **Use case, repository, builder, entity specs**: `app/domains/.../*_spec.rb`
- **Model specs**: Ditempatkan sejajar dengan model files di `app/models/.../*_spec.rb` (untuk main app) atau `engines/<engine>/app/models/<engine>/models/*_spec.rb` (untuk engine)

Model specs sekarang menyertakan ekspektasi untuk:
- Keberadaan kolom database
- **Type kolom database** (string, integer, decimal, datetime, dll.)
- Active Storage attachments (jika ada)
- Enum definitions (jika ada)

### Q: Apakah backward compatible?

**A:** Ya! Semua command lama masih bekerja. `--domain` option adalah additive feature.

### Q: Bisakah saya rename domain setelah generate?

**A:** Tidak direkomendasikan. Lebih baik regenerate dengan domain yang benar. Jika perlu rename, Anda harus update semua module names, require statements, dan references.

## Ringkasan Perubahan Terbaru

### ✅ Path Models Engine yang Benar

**Sebelum:**
```
engines/my_engine/app/models/my_engine/  # ❌ Wrong
```

**Sesudah:**
```
engines/my_engine/app/models/my_engine/models/  # ✅ Correct
```

### ✅ Model Spec Placement

**Model specs** sekarang ditempatkan **sejajar dengan model files**:

| Scenario | Model Location | Spec Location |
|----------|----------------|---------------|
| Main App | `app/models/models/user.rb` | `app/models/models/user_spec.rb` |
| Engine | `engines/my_engine/app/models/my_engine/models/company.rb` | `engines/my_engine/app/models/my_engine/models/company_spec.rb` |

### ✅ Enhanced Model Specs

Model specs sekarang menyertakan ekspektasi comprehensive untuk:

1. **Database Column Existence**: Verifikasi kolom ada di schema
2. **Column Types**: Ekspektasi eksplisit untuk type kolom (`:string`, `:integer`, `:decimal`, dll.)
3. **Active Storage Attachments**: Test untuk single/multiple file uploads
4. **Enum Definitions**: Validasi enum values jika ada

### ✅ Domain Scoping Namespace Rules

| Command | Domain Scope | Namespace Pattern |
|---------|-------------|-------------------|
| `rails g rider_kick:clean_arch --setup` | `core/` | `Core::*` |
| `rails g rider_kick:clean_arch --setup --domain admin/` | `admin/` | `Admin::*` |
| `rails g rider_kick:clean_arch --setup --engine MyEngine` | `my_engine/` | `MyEngine::*` |
| `rails g rider_kick:clean_arch --setup --engine MyEngine --domain admin/` | `my_engine/admin/` | `MyEngine::Admin::*` |

### ✅ File Structure Summary

```
# Main App
app/
├── domains/core/          # Domain scope
│   ├── entities/user.rb   # Core::Entities::User
│   ├── builders/user.rb   # Core::Builders::User
│   └── use_cases/...      # Core::UseCases::*
└── models/models/
    ├── user.rb            # Models::User
    └── user_spec.rb       # Model spec with column types

# Engine
engines/my_engine/
├── app/
│   ├── domains/my_engine/ # Engine + domain scope
│   │   ├── entities/company.rb    # MyEngine::Entities::Company
│   │   ├── builders/company.rb    # MyEngine::Builders::Company
│   │   └── use_cases/...          # MyEngine::UseCases::*
│   └── models/my_engine/
│       ├── application_record.rb
│       └── models/
│           ├── company.rb          # Models::MyEngine::Company
│           └── company_spec.rb     # Model spec with column types
```

## Examples dalam Gem Source

Lihat file test di `lib/generators/rider_kick/` untuk examples penggunaan domain scoping:

- `scaffold_generator_engine_spec.rb` - Engine + domain testing
- `structure_generator_engine_spec.rb` - Structure + domain testing
- `entity_type_mapping_spec.rb` - Domain path resolution

## Support

Jika Anda mengalami masalah dengan domain scoping:

1. Check dokumentasi ini
2. Lihat examples di gem source
3. Create issue di GitHub dengan command yang Anda jalankan dan error message
