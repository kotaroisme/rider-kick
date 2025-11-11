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

### Generate Scaffold

```bash
Description:
     Clean Architecture generator with automatic RSpec generation

Example:
    # Generate structure dan scaffold dengan domain default
    bin/rails generate rider_kick:structure Models::User actor:owner resource_owner:account resource_owner_id:account_id
    bin/rails generate rider_kick:scaffold users scope:dashboard

    # Generate structure dan scaffold dengan domain khusus
    bin/rails generate rider_kick:structure Models::User actor:admin resource_owner:account resource_owner_id:account_id --domain admin/
    bin/rails generate rider_kick:scaffold users scope:dashboard --domain admin/

    # Generate structure dan scaffold dalam Rails engine
    bin/rails generate rider_kick:structure Models::Order actor:user resource_owner:account resource_owner_id:account_id --engine OrderEngine --domain fulfillment/
    bin/rails generate rider_kick:scaffold orders --engine OrderEngine --domain fulfillment/

    # Generate structure dan scaffold untuk API domain
    bin/rails generate rider_kick:structure Models::Product actor:api resource_owner:account resource_owner_id:account_id --domain api/v1/
    bin/rails generate rider_kick:scaffold products --domain api/v1/
```

#### Scaffold dengan Domain Scoping

```bash
# Admin domain scaffold
bin/rails generate rider_kick:scaffold users scope:admin --domain admin/
# Output: app/domains/admin/use_cases/admin/users/...

# API v1 scaffold
bin/rails generate rider_kick:scaffold products --domain api/v1/
# Output: app/domains/api/v1/use_cases/products/...

# Engine scaffold
bin/rails generate rider_kick:scaffold orders --engine OrderEngine --domain fulfillment/
# Output: engines/order_engine/app/domains/fulfillment/use_cases/orders/...
```

### Generate Factory
```bash
Description:
     Generate FactoryBot factory for testing
     Automatically skips foreign key columns (*_id)
     
Example:
    To Generate factory with Faker calls:
        bin/rails generate rider_kick:factory Models::Article scope:core
        
    To Generate factory with static values:
        bin/rails generate rider_kick:factory Models::Article scope:core --static
        
    Standard factory (with Faker):
        FactoryBot.define do
          factory :article, class: 'Models::Article' do
            title { Faker::Lorem.sentence(word_count: 3) }
            content { Faker::Lorem.paragraph(sentence_count: 3) }
            published { [true, false].sample }
            # datetime/timestamp/time fields use Time.zone.now
            published_at { Time.zone.now }
          end
        end
    
    Static factory (with generated values):
        FactoryBot.define do
          factory :article, class: 'Models::Article' do
            title { 'Sit voluptatem aut' }
            content { 'Quia et et. Quis ut quo. Aut voluptas id.' }
            published { true }
            # Time fields remain Time.zone.now even with --static
            published_at { Time.zone.now }
          end
        end

```

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
## 🤝 Contributing

- Fork the repo & bundle install
- Create a feature branch: git checkout -b feat/your-feature
- Add tests where it makes sense
- ``` bundle exec rspec```
- Open a Pull Request 🎉

See CONTRIBUTING.md for details.