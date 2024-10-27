## Setup project

### Init Project
```bash
$ cp env.example .env.development
$ bundle install
$ rails db:create
$ rails db:migrate
$ rails db:seed
```
### Run Server
```bash
$ rails s -b 0.0.0.0 -e development
# open new tab then run
# open your browser then serve to http://0.0.0.0:3000
```

### Run Console
```bash
$ rails console
(dev)> use_case = Core::UseCases::GetVersion
(dev)> contract = use_case.contract!({})
(dev)> result   = use_case.new(contract).result
=> Success({:version=>"v1"}) # success
(dev)> result.success?
=> true
(dev)> result.success
=> {:version=>"0.0.1"}
```

Project Structure
## Clean Architecture
This structure provides helper interfaces and classes to assist in the construction of application with Clean Architecture, as described in Robert Martin's seminal book.

```
- app
  - domains 
    - core
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

Happy Coding!