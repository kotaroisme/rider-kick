# RiderKick
Rails generators for **Clean Architecture** on the backend: use cases, entities, repositories, builders, and utilities — organized for clarity and designed for speed.

> **🎉 NEW!** Domain scoping dengan `--domain` option! Organize domain files ke dalam scope yang berbeda (core/, admin/, api/v1/, dll.)
>
> **🎉 NEW!** Sekarang dengan automatic RSpec generation! Setiap file yang di-generate otomatis mendapat spec file-nya. [Lihat dokumentasi lengkap](SPEC_GENERATION.md)
>
> **🎉 NEW!** FactoryBot factory generator dengan smart Faker generation! [Lihat dokumentasi lengkap](FACTORY_GENERATOR.md)

This gem provides helper interfaces and classes to assist in the construction of application with
Clean Architecture, as described in [Robert Martin's seminal book](https://www.amazon.com/gp/product/0134494164).
---
## Features

- **Clean Architecture scaffolding**
  Creates `app/domains/<domain>/` with `entities/`, `use_cases/`, `repositories/`, `builders/`, and `utils/`.
- **Domain scoping dengan --domain option** 🆕
  Organize domain files ke dalam scope yang berbeda: `--domain core/`, `--domain admin/`, `--domain api/v1/`, dll.
- **Engine support dengan --engine option**
  Generate domain files dalam Rails engines: `--engine MyEngine --domain admin/`
- **Use-case-first "screaming architecture"**
  Encourages file names like `[role]_[action]_[subject].rb` for immediate intent (e.g., `admin_update_stock.rb`).
- **Rails-native generators**
  Pragmatic commands for bootstrapping domain structure and scaffolding.
- **Automatic RSpec generation** 🆕
  Generates comprehensive RSpec files for all generated code (use cases, repositories, builders, entities).
- **FactoryBot factory generator** 🆕
  Generates smart FactoryBot factories with automatic Faker values and foreign key skipping.
- **Idempotent, minimal friction**
  Safe to run more than once; prefers appending or no-ops over destructive changes.
---
## ✅ Compatibility

- **Ruby:** ≥ 3.2
- **Rails:** 7.1, 7.2, 8.0 (up to < 8.1)

---
## Installation

And then execute:
```bash
    $ rails new kotaro_minami -d=postgresql -T --skip-javascript --skip-asset-pipeline
    $ bundle install
    $ bundle add rider-kick
    $ rails generate rider_kick:clean_arch --setup
    $ rails db:drop db:create db:migrate db:seed
    $ rails g model models/products name price:decimal is_published:boolean
    $ rails generate rider_kick:structure Models::Product actor:owner
    $ rails generate rider_kick:scaffold products scope:dashboard
```

### Quick Examples with Domain Scoping

```bash
# Setup dengan domain default (core/)
$ rails generate rider_kick:clean_arch --setup

# Setup untuk admin domain
$ rails generate rider_kick:clean_arch --setup --domain admin/

# Setup untuk API v1 domain
$ rails generate rider_kick:clean_arch --setup --domain api/v1/

# Setup dalam Rails engine
$ rails generate rider_kick:clean_arch --setup --engine MyEngine --domain mobile/
```
### OPTIONAL
```bash
    $ bundle add sun-sword
```
---
## Usage

### Initial Setup (Required Once)

#### Basic Setup (Default Domain)
```bash
# 1. Create new Rails app
rails new kotaro_minami -d=postgresql -T --skip-javascript --skip-asset-pipeline

# 2. Add rider-kick gem
bundle add rider-kick

# 3. Setup Clean Architecture structure (includes RSpec setup & helpers)
bin/rails generate rider_kick:clean_arch --setup
```

#### Advanced Setup with Domain Scoping

```bash
# Setup untuk domain tertentu
bin/rails generate rider_kick:clean_arch --setup --domain admin/

# Setup untuk API domain
bin/rails generate rider_kick:clean_arch --setup --domain api/v1/

# Setup dalam Rails engine
bin/rails generate rider_kick:clean_arch --setup --engine MyEngine --domain core/

# Setup engine dengan domain khusus
bin/rails generate rider_kick:clean_arch --setup --engine AdminEngine --domain admin/
```

### Domain Scoping Explanation

**--domain option** memungkinkan Anda mengorganisir domain files ke dalam scope yang berbeda:

- **Default**: `--domain core/` → `app/domains/core/`
- **Admin domain**: `--domain admin/` → `app/domains/admin/`
- **API domain**: `--domain api/v1/` → `app/domains/api/v1/`
- **Engine**: `--engine MyEngine --domain mobile/` → `engines/my_engine/app/domains/mobile/`

### Setup Output

This setup will create:
- Domain structure (`app/domains/<domain>/` or `engines/<engine>/app/domains/<domain>/`)
- RSpec configuration with helpers (`spec/support/class_stubber.rb`, etc.)
- Database configuration
- Initializers

#### Generated Structure Examples

**Main App dengan domain default:**
```
app/
  domains/
    core/           # --domain core/ (default)
      entities/
      builders/
      repositories/
      use_cases/
      utils/
```

**Main App dengan multiple domains:**
```
app/
  domains/
    core/           # --domain core/
    admin/          # --domain admin/
    api/
      v1/           # --domain api/v1/
```

**Rails Engine:**
```
engines/
  my_engine/
    app/
      domains/
        core/       # --engine MyEngine --domain core/
        mobile/     # --engine MyEngine --domain mobile/
```

### Generate Structure

Generator untuk membuat file struktur YAML dari model yang sudah ada. File YAML ini berisi konfigurasi yang akan digunakan oleh generator `scaffold`.

```bash
rails generate rider_kick:structure MODEL_NAME [SETTINGS] [OPTIONS]
```

**Required Arguments:**
- `MODEL_NAME` - Nama model class (e.g., `Models::User`, `Models::Article`)
- `actor` - Actor/role yang akan menggunakan use case (e.g., `actor:user`, `actor:admin`)
- `resource_owner` - Nama resource owner untuk authorization (e.g., `resource_owner:account`)
- `resource_owner_id` - Nama kolom resource owner ID (e.g., `resource_owner_id:account_id`)

**Optional Settings:**
- `uploaders` - Daftar kolom uploader dipisah koma (e.g., `uploaders:avatar,images`)
- `search_able` - Daftar kolom yang bisa di-search dipisah koma (e.g., `search_able:name,email`)

**Options:**
- `--engine ENGINE_NAME` - Specify engine name (e.g., `Core`, `Admin`)
- `--domain DOMAIN` - Specify domain scope (e.g., `core/`, `admin/`, `api/v1/`)

**Examples:**
```bash
# Basic structure dengan domain default
rails generate rider_kick:structure Models::User actor:owner resource_owner:account resource_owner_id:account_id

# Dengan uploaders dan searchable fields
rails generate rider_kick:structure Models::Product \
  actor:admin \
  resource_owner:account \
  resource_owner_id:account_id \
  uploaders:image,documents \
  search_able:name,sku \
  --domain admin/

# Dalam Rails engine
rails generate rider_kick:structure Models::Order \
  actor:user \
  resource_owner:account \
  resource_owner_id:account_id \
  --engine OrderEngine \
  --domain fulfillment/
```

**Output:** File YAML di `db/structures/<model_name>_structure.yaml` yang berisi konfigurasi lengkap untuk scaffold generator.

### Generate Scaffold

Generator utama untuk generate use cases, repositories, entities, builders, dan spec files berdasarkan structure YAML yang sudah dibuat.

```bash
rails generate rider_kick:scaffold STRUCTURE_NAME [SCOPE] [OPTIONS]
```

**Required Arguments:**
- `STRUCTURE_NAME` - Nama structure (plural, tanpa `_structure.yaml`). Contoh: `users`, `products`, `orders`

**Optional Arguments:**
- `scope:SCOPE_NAME` - Route scope (e.g., `scope:dashboard`, `scope:admin`)

**Options:**
- `--engine ENGINE_NAME` - Specify engine name (e.g., `Core`, `Admin`)
- `--domain DOMAIN` - Specify domain scope (e.g., `core/`, `admin/`, `api/v1/`)

**Examples:**
```bash
# Basic scaffold dengan domain default
rails generate rider_kick:scaffold users scope:dashboard

# Dengan domain khusus
rails generate rider_kick:scaffold users scope:admin --domain admin/

# Dalam Rails engine
rails generate rider_kick:scaffold orders --engine OrderEngine --domain fulfillment/

# API domain
rails generate rider_kick:scaffold products --domain api/v1/
```

**Output:**
- Use cases: `app/domains/<domain>/use_cases/<scope>/<resource>/`
- Repositories: `app/domains/<domain>/repositories/<resource>/`
- Entities: `app/domains/<domain>/entities/`
- Builders: `app/domains/<domain>/builders/`
- Spec files untuk semua generated code

### Generate Factory

Generator untuk membuat FactoryBot factory files dengan smart Faker generation. Otomatis skip foreign key columns dan generate Faker values berdasarkan tipe kolom.

```bash
rails generate rider_kick:factory MODEL_NAME [SCOPE] [OPTIONS]
```

**Required Arguments:**
- `MODEL_NAME` - Nama model class (e.g., `Models::Article`, `Models::User`)

**Optional Arguments:**
- `scope:SCOPE_NAME` - Scope untuk factory (e.g., `scope:core`)

**Options:**
- `--engine ENGINE_NAME` - Specify engine name (e.g., `Core`, `Admin`)
- `--static` - Generate static values instead of Faker calls (time fields tetap menggunakan `Time.zone.now`)

**Examples:**
```bash
# Factory dengan Faker (default)
rails generate rider_kick:factory Models::Article scope:core

# Factory dengan static values
rails generate rider_kick:factory Models::Article scope:core --static

# Dalam Rails engine
rails generate rider_kick:factory Models::Order scope:fulfillment --engine OrderEngine
```

**Smart Faker Mapping:**
Generator menggunakan smart mapping berdasarkan nama kolom dan tipe:
- `string` dengan `email` → `Faker::Internet.email`
- `string` dengan `name` → `Faker::Name.name`
- `text` dengan `description`/`content` → `Faker::Lorem.paragraph`
- `integer` dengan `price`/`amount` → `Faker::Number.between(from: 1000, to: 1000000)`
- `decimal` dengan `price` → `Faker::Commerce.price`
- `boolean` → `[true, false].sample`
- `datetime`/`timestamp`/`time` → `Time.zone.now` (selalu)
- Dan banyak lagi...

**Kolom yang Di-skip:**
- `id`, `created_at`, `updated_at`, `type`
- Semua foreign key columns (`*_id`)

📖 **[Complete Factory Generator Documentation →](FACTORY_GENERATOR.md)**
📖 **[Domain Scoping Guide →](DOMAIN_SCOPING.md)**
---
## Generated Structure

### Default Structure (Main App)
```text
app/
  domains/
    core/                    # Default domain (--domain core/)
      entities/
      builders/
      repositories/
      use_cases/
      utils/
```

### Multiple Domains Structure
```text
app/
  domains/
    core/                    # Main domain (--domain core/)
      entities/
      builders/
      repositories/
      use_cases/
      utils/
    admin/                   # Admin domain (--domain admin/)
      entities/
      builders/
      repositories/
      use_cases/
      utils/
    api/
      v1/                    # API domain (--domain api/v1/)
        entities/
        builders/
        repositories/
        use_cases/
        utils/
```

### Rails Engine Structure
```text
engines/
  my_engine/
    app/
      domains/
        core/                # Engine domain (--engine MyEngine --domain core/)
          entities/
          builders/
          repositories/
          use_cases/
          utils/
        mobile/              # Mobile domain (--engine MyEngine --domain mobile/)
          entities/
          builders/
          repositories/
          use_cases/
          utils/
```

---

## Complete Generator Documentation

### Generator Overview

Gem ini menyediakan **4 generator utama**:

1. **`rider_kick:clean_arch`** - Setup Clean Architecture structure
2. **`rider_kick:structure`** - Generate structure YAML file dari model
3. **`rider_kick:scaffold`** - Generate use cases, repositories, entities, builders
4. **`rider_kick:factory`** - Generate FactoryBot factory files

### 1. Generator: `rider_kick:clean_arch`

**Deskripsi:**
Generator untuk setup awal struktur Clean Architecture. Generator ini harus dijalankan pertama kali sebelum menggunakan generator lainnya.

**Command:**
```bash
rails generate rider_kick:clean_arch [OPTIONS]
```

**Options:**

| Option | Type | Default | Deskripsi |
|--------|------|---------|-----------|
| `--setup` | boolean | `false` | **WAJIB** - Setup domain structure. Harus dispecify untuk membuat struktur domain. |
| `--engine` | string | `nil` | Specify engine name (e.g., `Core`, `Admin`). Jika dispecify, `--setup` otomatis dianggap true. |
| `--domain` | string | `''` | Specify domain scope (e.g., `core/`, `admin/`, `api/v1/`). Default: `core/` |

**Yang Dihasilkan:**

1. **Domain Structure:**
   - `app/domains/<domain>/use_cases/` (dengan subfolder `contract/`)
   - `app/domains/<domain>/repositories/`
   - `app/domains/<domain>/builders/`
   - `app/domains/<domain>/entities/`
   - `app/domains/<domain>/utils/`

2. **Base Files:**
   - Contract files: `pagination.rb`, `default.rb`
   - Use case: `get_version.rb`
   - Builders: `error.rb`, `pagination.rb`
   - Entities: `error.rb`, `pagination.rb`
   - Repository: `abstract_repository.rb`
   - Utils: `abstract_utils.rb`, `request_methods.rb`

3. **Configuration Files (Main App Only):**
   - Initializers: `clean_archithecture.rb`, `generators.rb`, `hashie.rb`, `version.rb`, `zeitwerk.rb`, `pagy.rb`, `route_extensions.rb`
   - Database config: `config/database.yml`
   - Environment files: `.env.development`, `.env.production`, `.env.test`, `env.example`
   - Git ignore: `.gitignore`
   - Rubocop: `.rubocop.yml`
   - README: `README.md`

4. **RSpec Setup (Main App Only):**
   - RSpec configuration
   - Support files: `class_stubber.rb`, `file_stuber.rb`, `repository_stubber.rb`
   - FactoryBot & Faker setup
   - `spec/rails_helper.rb`

5. **Database:**
   - Migration: `db/migrate/20220613145533_init_database.rb`
   - Structures directory: `db/structures/`

6. **Models:**
   - `app/models/application_record.rb` (main app)
   - `app/models/models/models.rb`

7. **Gem Dependencies (ditambahkan ke Gemfile):**
   - `rspec-rails`, `factory_bot_rails`, `faker`, `shoulda-matchers`
   - `dotenv-rails`
   - `hashie`
   - `image_processing`, `ruby-vips`
   - `pagy`

**Catatan Penting:**
- Option `--setup` **WAJIB** dispecify untuk membuat struktur domain
- Jika `--engine` dispecify, `--setup` otomatis dianggap true
- Untuk engine, beberapa setup (seperti initializers) tidak dilakukan karena dilakukan di main app

### 2. Generator: `rider_kick:structure`

**Deskripsi:**
Generator untuk membuat file struktur YAML dari model yang sudah ada. File YAML ini berisi konfigurasi yang akan digunakan oleh generator `scaffold` untuk generate use cases, repositories, entities, dan builders.

**Command:**
```bash
rails generate rider_kick:structure MODEL_NAME [SETTINGS] [OPTIONS]
```

**Required Settings:**

| Setting | Deskripsi | Contoh |
|---------|-----------|--------|
| `actor` | Actor/role yang akan menggunakan use case | `actor:user`, `actor:admin`, `actor:owner` |
| `resource_owner` | Nama resource owner (untuk authorization) | `resource_owner:account` |
| `resource_owner_id` | Nama kolom resource owner ID | `resource_owner_id:account_id` |

**Optional Settings:**

| Setting | Deskripsi | Contoh |
|---------|-----------|--------|
| `uploaders` | Daftar kolom uploader (dipisah koma). Otomatis detect single/multiple berdasarkan singular/plural | `uploaders:avatar,images,picture` |
| `search_able` | Daftar kolom yang bisa di-search (dipisah koma) | `search_able:name,email,title` |

**Options:**

| Option | Type | Default | Deskripsi |
|--------|------|---------|-----------|
| `--engine` | string | `nil` | Specify engine name (e.g., `Core`, `Admin`) |
| `--domain` | string | `''` | Specify domain scope (e.g., `core/`, `admin/`, `api/v1/`) |

**Format YAML yang Dihasilkan:**

```yaml
model: Models::User
resource_name: users
actor: owner
resource_owner: account
resource_owner_id: account_id
uploaders:
  - name: avatar
    type: single
  - name: images
    type: multiple
search_able: []
domains:
  action_list:
    use_case:
      contract: [...]
  action_create:
    use_case:
      contract: [...]
  action_update:
    use_case:
      contract: [...]
  action_fetch_by_id:
    use_case:
      contract: [...]
  action_destroy:
    use_case:
      contract: [...]
entity:
  db_attributes: [...]
```

**Catatan Penting:**
- Model harus sudah ada sebelum menjalankan generator ini
- Generator ini membaca kolom dari model untuk generate contract dan entity attributes
- Kolom `id`, `created_at`, `updated_at`, `type` otomatis di-exclude dari contract fields
- Uploader type (single/multiple) otomatis di-detect berdasarkan singular/plural name

### 3. Generator: `rider_kick:scaffold`

**Deskripsi:**
Generator utama untuk generate use cases, repositories, entities, builders, dan spec files berdasarkan structure YAML yang sudah dibuat oleh generator `structure`.

**Command:**
```bash
rails generate rider_kick:scaffold STRUCTURE_NAME [SCOPE] [OPTIONS]
```

**Yang Dihasilkan:**

1. **Use Cases** (di `app/domains/<domain>/use_cases/<scope>/<resource>/`):
   - `{actor}_create_{resource}.rb` - Create use case
   - `{actor}_update_{resource}.rb` - Update use case
   - `{actor}_list_{resource}.rb` - List use case
   - `{actor}_fetch_by_id_{resource}.rb` - Fetch by ID use case
   - `{actor}_destroy_{resource}.rb` - Destroy use case
   - Spec files untuk setiap use case

2. **Repositories** (di `app/domains/<domain>/repositories/<resource>/`):
   - `create_{resource}.rb` - Create repository
   - `update_{resource}.rb` - Update repository
   - `list_{resource}.rb` - List repository
   - `fetch_by_id_{resource}.rb` - Fetch by ID repository
   - `destroy_{resource}.rb` - Destroy repository
   - Spec files untuk setiap repository

3. **Entities** (di `app/domains/<domain>/entities/`):
   - `{resource}.rb` - Entity class dengan attributes dari model

4. **Builders** (di `app/domains/<domain>/builders/`):
   - `{resource}.rb` - Builder class untuk convert ActiveRecord ke Entity
   - Spec file untuk builder

5. **Model Spec** (di `app/models/models/` atau `app/models/<engine>/`):
   - `{resource}_spec.rb` - Model spec file

6. **Model Attachment** (auto-inject ke model file):
   - `has_one_attached` atau `has_many_attached` untuk uploaders
   - Hanya jika model file sudah ada

**Catatan Penting:**
- Structure YAML file harus sudah ada (dibuat dengan generator `structure`)
- Generator ini membaca konfigurasi dari structure YAML file
- Validasi dilakukan untuk memastikan filter fields dan entity fields ada di model
- Uploader attachments otomatis di-inject ke model file jika file sudah ada
- Semua file yang di-generate otomatis mendapat spec file

### 4. Generator: `rider_kick:factory`

**Deskripsi:**
Generator untuk membuat FactoryBot factory files dengan smart Faker generation. Otomatis skip foreign key columns dan generate Faker values berdasarkan tipe kolom.

**Command:**
```bash
rails generate rider_kick:factory MODEL_NAME [SCOPE] [OPTIONS]
```

**Smart Faker Mapping:**

Generator ini menggunakan smart mapping berdasarkan nama kolom dan tipe:

| Tipe Kolom | Nama Kolom Contains | Faker Expression |
|------------|---------------------|-------------------|
| `string` | `email` | `Faker::Internet.email` |
| `string` | `name` | `Faker::Name.name` |
| `string` | `phone` | `Faker::PhoneNumber.phone_number` |
| `string` | `address` | `Faker::Address.full_address` |
| `string` | `title` | `Faker::Lorem.sentence(word_count: 3)` |
| `string` | `code` | `Faker::Alphanumeric.alphanumeric(number: 10)` |
| `string` | (default) | `Faker::Lorem.word` |
| `text` | `description`, `content`, `body` | `Faker::Lorem.paragraph(sentence_count: 3)` |
| `text` | (default) | `Faker::Lorem.sentence` |
| `integer` | `count`, `quantity` | `Faker::Number.between(from: 1, to: 100)` |
| `integer` | `age` | `Faker::Number.between(from: 18, to: 80)` |
| `integer` | `price`, `amount` | `Faker::Number.between(from: 1000, to: 1000000)` |
| `integer` | (default) | `Faker::Number.number(digits: 5)` |
| `decimal` | `price`, `amount` | `Faker::Commerce.price` |
| `decimal` | (default) | `Faker::Number.decimal(l_digits: 4, r_digits: 2)` |
| `boolean` | - | `[true, false].sample` |
| `date` | - | `Faker::Date.between(from: 1.year.ago, to: Date.today)` |
| `datetime`, `timestamp`, `time` | - | `Time.zone.now` (selalu, bahkan dengan `--static`) |
| `uuid` | - | `SecureRandom.uuid` |
| `json`, `jsonb` | - | `{ key: Faker::Lorem.word, value: Faker::Lorem.sentence }` |

**Kolom yang Di-skip:**
- `id` - Primary key
- `created_at` - Timestamp
- `updated_at` - Timestamp
- `type` - STI type
- `*_id` - Semua foreign key columns (ending with `_id`)

**Catatan Penting:**
- Model harus sudah ada sebelum menjalankan generator ini
- Foreign key columns otomatis di-skip
- Time-based columns selalu menggunakan `Time.zone.now`, bahkan dengan `--static`
- Dengan `--static`, Faker expressions akan di-evaluate dan hasilnya dijadikan static values

### Complete Workflow Example

```bash
# 1. Setup Clean Architecture (sekali di awal)
rails generate rider_kick:clean_arch --setup --domain core/

# 2. Buat model
rails g model models/products name:string price:decimal is_published:boolean

# 3. Generate structure YAML
rails generate rider_kick:structure Models::Product \
  actor:admin \
  resource_owner:account \
  resource_owner_id:account_id \
  uploaders:image \
  search_able:name,description \
  --domain core/

# 4. Generate scaffold (use cases, repositories, entities, builders)
rails generate rider_kick:scaffold products scope:dashboard --domain core/

# 5. Generate factory untuk testing
rails generate rider_kick:factory Models::Product scope:core
```

---
## Philosophy

The intention of this gem is to help you build applications that are built from the use case down,
and decisions about I/O can be deferred until the last possible moment.

### Clean Architecture
This structure provides helper interfaces and classes to assist in the construction of application with Clean Architecture, as described in Robert Martin's seminal book.

```
- app
  - models
    - models
      - ...
  - domains
    - core                    # Default domain (--domain core/)
      - entities (Contract Response)
      - builders
      - repositories (Business logic)
      - use_cases (Just Usecase)
      - utils (Class Reusable)
    - admin                   # Admin domain (--domain admin/)
      - entities
      - builders
      - repositories
      - use_cases
      - utils
    - api/v1                  # API domain (--domain api/v1/)
      - entities
      - builders
      - repositories
      - use_cases
      - utils
```

### Domain Scoping untuk Large Applications
Untuk aplikasi yang besar, Anda dapat menggunakan `--domain` option untuk mengorganisir domain files berdasarkan konteks bisnis:

- **`core/`**: Domain utama aplikasi (default)
- **`admin/`**: Domain untuk fitur admin/pengelolaan
- **`api/v1/`**: Domain untuk API versioning
- **`mobile/`**: Domain untuk mobile-specific logic
- **`reporting/`**: Domain untuk laporan dan analytics

Ini membantu menjaga kode tetap terorganisir dan memudahkan maintenance seiring pertumbuhan aplikasi.
### Screaming architecture - use cases as an organisational principle
Uncle Bob suggests that your source code organisation should allow developers to easily find a listing of all use cases your application provides. Here's an example of how this might look in a this application.
```
- app
  - models
    - models
      - ...
  - domains 
    - core
      ...
      - usecase
        - retail_customer_opens_bank_account.rb
        - retail_customer_makes_deposit.rb
        - ...
```

Note that the use case name contains:

- the user role
- the action
- the (sometimes implied) subject
```ruby
    [user role][action][subject].rb
    # retail_customer_opens_bank_account.rb
    # admin_fetch_info.rb [specific usecase]
    # fetch_info.rb [generic usecase] every role can access it
```
---
---

## Dependencies

### Runtime Dependencies:
- `activesupport` >= 7.0, < 9.0
- `dry-matcher` >= 1.0, < 2.0
- `dry-monads` >= 1.6, < 2.0
- `dry-struct` >= 1.6, < 2.0
- `dry-types` >= 1.7, < 2.0
- `dry-validation` >= 1.9, < 2.0
- `hashie` >= 5.0, < 6.0
- `thor` >= 1.2, < 2.0

### Development Dependencies:
- `bundler` >= 2.4, < 3.0
- `generator_spec` >= 0.9, < 1.0
- `rake` >= 13.0, < 14.0
- `rspec` >= 3.12, < 4.0
- `rubocop` >= 1.63, < 2.0
- `rubocop-rspec` >= 3.0, < 4.0

---

## 🤝 Contributing

- Fork the repo & bundle install
- Create a feature branch: git checkout -b feat/your-feature
- Add tests where it makes sense
- ``` bundle exec rspec```
- Open a Pull Request 🎉

See CONTRIBUTING.md for details.