# RiderKick
This gem provides helper interfaces and classes to assist in the construction of application with
Clean Architecture, as described in [Robert Martin's seminal book](https://www.amazon.com/gp/product/0134494164).


## Installation

Add this line to your application's Gemfile:

```ruby
gem 'rider-kick'
```

And then execute:

    $ bundle install
    $ bundle binstubs rider-kick
    $ rails generate rider_kick:clean_arch --setup
    $ rails db:drop db:create db:migrate db:seed
    $ rubocop -a

## Usage
```bash
Description:
Clean Architecture generator

Example:
    To Generate Structure:
        bin/rails  generate rider_kick:clean_arch --setup

        To undo:
           bin/rails destroy rider_kick:clean_arch --setup

    To Generate scaffold:
        bin/rails  generate rider_kick:scaffold Models::Contact actor:user

        To undo:
           bin/rails destroy rider_kick:scaffold Models::Contact actor:user

    To Generate Domain:
        bin/rails  generate rider_kick:blank actor:user action:create scope:Contact --use_case --repository --builder --entity

        To undo:
           bin/rails destroy rider_kick:blank actor:user action:create scope:Contact --use_case --repository --builder --entity

```

## Philosophy

The intention of this gem is to help you build applications that are built from the use case down,
and decisions about I/O can be deferred until the last possible moment.

## Clean Architecture
This structure provides helper interfaces and classes to assist in the construction of application with Clean Architecture, as described in Robert Martin's seminal book.

```
- app
  - services
    - api
      - ...
  - domains 
    - entities (Contract Response)
    - builder
    - repositories (Business logic)
    - use_cases (Just Usecase)
    - utils (Class Reusable)
```
## Screaming architecture - use cases as an organisational principle
Uncle Bob suggests that your source code organisation should allow developers to easily find a listing of all use cases your application provides. Here's an example of how this might look in a this application.
```
- app
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

