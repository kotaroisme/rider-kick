# RiderKick
Rails generators for **Clean Architecture** on the backend: use cases, entities, repositories, builders, and utilities — organized for clarity and designed for speed.

This gem provides helper interfaces and classes to assist in the construction of application with
Clean Architecture, as described in [Robert Martin's seminal book](https://www.amazon.com/gp/product/0134494164).
---
## Features

- **Clean Architecture scaffolding**  
  Creates `app/domains` with `entities/`, `use_cases/`, `repositories/`, `builders/`, and `utils/`.
- **Use-case-first “screaming architecture”**  
  Encourages file names like `[role]_[action]_[subject].rb` for immediate intent (e.g., `admin_update_stock.rb`).
- **Rails-native generators**  
  Pragmatic commands for bootstrapping domain structure and scaffolding.
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
```bash
Description:
     Clean Architecture generator
     rails new kotaro_minami -d=postgresql -T --skip-javascript --skip-asset-pipeline
     
Example:
    To Generate scaffold:
        bin/rails generate rider_kick:clean_arch --setup
        bin/rails generate rider_kick:structure Models::User actor:owner
        bin/rails generate rider_kick:scaffold users scope:dashboard

```
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