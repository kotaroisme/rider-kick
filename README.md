# RiderKick
Rails generators for **Clean Architecture** on the backend: use cases, entities, repositories, builders, and utilities — organized for clarity and designed for speed.

> **🎉 NEW!** Sekarang dengan automatic RSpec generation! Setiap file yang di-generate otomatis mendapat spec file-nya. [Lihat dokumentasi lengkap](SPEC_GENERATION.md)
> 
> **🎉 NEW!** FactoryBot factory generator dengan smart Faker generation! [Lihat dokumentasi lengkap](FACTORY_GENERATOR.md)

This gem provides helper interfaces and classes to assist in the construction of application with
Clean Architecture, as described in [Robert Martin's seminal book](https://www.amazon.com/gp/product/0134494164).
---
## Features

- **Clean Architecture scaffolding**  
  Creates `app/domains` with `entities/`, `use_cases/`, `repositories/`, `builders/`, and `utils/`.
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
### OPTIONAL
```bash
    $ bundle add sun-sword
```
---
## Usage

### Initial Setup (Required Once)
```bash
# 1. Create new Rails app
rails new kotaro_minami -d=postgresql -T --skip-javascript --skip-asset-pipeline

# 2. Add rider-kick gem
bundle add rider-kick

# 3. Setup Clean Architecture structure (includes RSpec setup & helpers)
bin/rails generate rider_kick:clean_arch --setup
```

This setup will create:
- Domain structure (`app/domains/core/`)
- RSpec configuration with helpers (`spec/support/class_stubber.rb`, etc.)
- Database configuration
- Initializers

### Generate Scaffold
```bash
Description:
     Clean Architecture generator with automatic RSpec generation
     
Example:
    To Generate scaffold with specs:
        bin/rails generate rider_kick:structure Models::User actor:owner
        bin/rails generate rider_kick:scaffold users scope:dashboard

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
---
## Generated Structure

```text
app/
  domains/
    core/
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
    - core
      ...
        - entities (Contract Response)
        - builder
        - repositories (Business logic)
        - use_cases (Just Usecase)
        - utils (Class Reusable)
```
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