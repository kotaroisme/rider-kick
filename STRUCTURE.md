# Dokumentasi Structure.yaml - RiderKick Generator

File `structure.yaml` adalah file konfigurasi terpusat yang digunakan oleh RiderKick generator untuk menghasilkan domain logic, controllers, dan views dalam pola clean architecture. File ini berfungsi sebagai **single source of truth** untuk code generation.

## Lokasi File

File `structure.yaml` biasanya terletak di:
- **Main app**: `db/structures/{resource_name}_structure.yaml`
- **Engine**: `engines/{engine_name}/db/structures/{resource_name}_structure.yaml`

## Cara Generate

File ini biasanya di-generate otomatis menggunakan generator:

```bash
rails generate rider_kick:structure Models::Article actor:owner resource_owner:account resource_owner_id:account_id uploaders:images,assets search_able:title,body
```

Setelah file di-generate, Anda dapat memodifikasinya secara manual dan menjalankan `rider_kick:scaffold` untuk memperbarui code sesuai dengan perubahan.

---

## Struktur Lengkap

Berikut adalah contoh lengkap file `structure.yaml`:

```yaml
# RiderKick Structure Definition for Articles
# This file acts as a centralized contract for code generation.
# Modifying this file and re-running 'rider_kick:scaffold' will update the domain logic.

model: Models::Article
resource_name: articles
resource_owner_id: account_id # account_id
resource_owner: account # account
actor: owner # user
actor_id: owner_id # user_id

fields:
  - account_id
  - title
  - body
  - published_at
  - user_id
  - images

uploaders:
  - { name: 'images', type: 'multiple' }
  - { name: 'assets', type: 'multiple' }

search_able:
  - title
  - body

# ---- Enriched metadata (opsional, untuk tooling/insight) ----
schema:
  columns:
    - name: id
      type: uuid
      sql_type: uuid
      null: false
    - name: account_id
      type: uuid
      sql_type: uuid
      null: true
    - name: title
      type: string
      sql_type: character varying
      null: true
    - name: body
      type: text
      sql_type: text
      null: true
    - name: published_at
      type: datetime
      sql_type: timestamp without time zone
      null: true
    - name: user_id
      type: uuid
      sql_type: uuid
      null: true
    - name: images
      type: text
      sql_type: text
      null: true
    - name: created_at
      type: datetime
      sql_type: timestamp without time zone
      null: false
    - name: updated_at
      type: datetime
      sql_type: timestamp without time zone
      null: false
  foreign_keys: []
  indexes: []
  enums: {}

controllers:
  list_fields:
    - account_id
    - title
    - body
    - published_at
    - user_id
  show_fields:
    - id
    - account_id
    - title
    - body
    - published_at
    - user_id
    - images
    - created_at
    - updated_at
  form_fields:
    - name: account_id
      type: uuid
    - name: title
      type: string
    - name: body
      type: text
    - name: published_at
      type: datetime
    - name: user_id
      type: uuid
    - name: images
      type: files

domains:
  action_list:
    use_case:
      contract:
        - "optional(:title).maybe(:string)"
        - "optional(:body).maybe(:string)"
    repository:
      filters:
        - { field: 'title', type: 'search' }
        - { field: 'body', type: 'search' }

  action_fetch_by_id:
    use_case:
      contract:
        - "required(:id).filled(:string)"
        - "required(:account_id).filled(:string)"
        # optional search fields: title
        # optional search fields: body

  action_create:
    use_case:
      contract:
        - "required(:account_id).filled(:string)"
        - "required(:title).filled(:string)"
        - "optional(:body).maybe(:string)"
        - "optional(:published_at).maybe(:time)"
        - "optional(:user_id).maybe(:string)"

  action_update:
    use_case:
      contract:
        - "required(:id).filled(:string)"
        - "required(:account_id).filled(:string)"
        - "optional(:title).maybe(:string)"
        - "optional(:body).maybe(:string)"
        - "optional(:published_at).maybe(:time)"
        - "optional(:user_id).maybe(:string)"

  action_destroy:
    use_case:
      contract:
        - "required(:id).filled(:string)"
        - "required(:account_id).filled(:string)"

entity:
  skipped_fields:
    - id
    - created_at
    - updated_at
  db_attributes:
    - account_id
    - title
    - body
    - published_at
    - user_id
```

---

## Dokumentasi Key per Section

### 1. Metadata Dasar

#### `model` (required)
- **Tipe**: String
- **Deskripsi**: Nama kelas model ActiveRecord (dengan namespace penuh)
- **Contoh**: 
  - `Models::Article`
  - `Models::User`
  - `Admin::Models::Product`
- **Digunakan untuk**: Referensi model saat generate code
- **Catatan**: Harus sesuai dengan nama kelas model yang ada di aplikasi

#### `resource_name` (required)
- **Tipe**: String
- **Deskripsi**: Nama resource dalam bentuk plural dan underscore (snake_case)
- **Contoh**: 
  - `articles`
  - `users`
  - `blog_posts`
  - `order_items`
- **Digunakan untuk**: 
  - Nama file yang di-generate
  - Route path
  - Scope class name
- **Catatan**: Auto-generated dari `model` name (pluralized dan underscored)

#### `resource_owner_id` (required)
- **Tipe**: String
- **Deskripsi**: Nama kolom foreign key untuk resource owner (multi-tenancy)
- **Contoh**: 
  - `account_id`
  - `organization_id`
  - `tenant_id`
  - `company_id`
- **Digunakan untuk**: 
  - Multi-tenancy scoping
  - Authorization checks
  - Contract validation
- **Catatan**: Wajib disediakan saat generate structure

#### `resource_owner` (required)
- **Tipe**: String
- **Deskripsi**: Nama model resource owner (tanpa namespace)
- **Contoh**: 
  - `account`
  - `organization`
  - `tenant`
  - `company`
- **Digunakan untuk**: 
  - Authorization context
  - Documentation
- **Catatan**: Harus sesuai dengan model yang direferensikan oleh `resource_owner_id`

#### `actor` (required)
- **Tipe**: String
- **Deskripsi**: Nama actor yang melakukan aksi (user/role)
- **Contoh**: 
  - `user`
  - `owner`
  - `admin`
  - `manager`
- **Digunakan untuk**: Authorization context dan tracking
- **Catatan**: Bisa berupa role atau user type

#### `actor_id` (auto-generated)
- **Tipe**: String
- **Deskripsi**: Nama kolom foreign key untuk actor (auto-generated dari `actor`)
- **Contoh**: 
  - `user_id` (jika actor: user)
  - `owner_id` (jika actor: owner)
- **Digunakan untuk**: Tracking siapa yang melakukan aksi
- **Catatan**: Auto-generated, tidak perlu di-set manual

---

### 2. Fields & Uploaders

#### `fields` (required)
- **Tipe**: Array of Strings
- **Deskripsi**: Daftar kolom database yang digunakan dalam contract. Field yang otomatis di-exclude: `id`, `created_at`, `updated_at`, `type` (STI), dan semua uploaders.
- **Contoh**:
  ```yaml
  fields:
    - account_id
    - title
    - body
    - published_at
    - user_id
    - status
  ```
- **Digunakan untuk**: 
  - Generate contract validation
  - Generate form fields
  - Generate entity attributes
- **Catatan**: Field uploaders tidak termasuk di sini, mereka ada di section `uploaders` terpisah

#### `uploaders` (optional)
- **Tipe**: Array of Objects atau `[]` (empty array)
- **Deskripsi**: Daftar uploader/file fields dengan tipe (single/multiple)
- **Format**:
  ```yaml
  uploaders:
    - { name: 'images', type: 'multiple' }   # plural = multiple files
    - { name: 'avatar', type: 'single' }       # singular = single file
    - { name: 'documents', type: 'multiple' }
  ```
- **Atau kosong**:
  ```yaml
  uploaders: []
  ```
- **Type Detection**: 
  - Jika nama field **plural** (images, assets, documents) → `type: 'multiple'`
  - Jika nama field **singular** (avatar, picture, logo) → `type: 'single'`
- **Digunakan untuk**: 
  - Generate file upload handling di form
  - Generate entity uploader definitions
  - Generate controller file handling
- **Catatan**: Field uploaders juga harus ada di kolom database (biasanya `text` atau `jsonb`)

#### `search_able` (optional)
- **Tipe**: Array of Strings atau `[]` (empty array)
- **Deskripsi**: Daftar field yang bisa digunakan untuk pencarian/filtering
- **Contoh**:
  ```yaml
  search_able:
    - title
    - body
    - email
    - name
  ```
- **Atau kosong**:
  ```yaml
  search_able: []
  ```
- **Digunakan untuk**: 
  - Generate filter di repository list
  - Generate contract untuk action_list
  - Generate search functionality
- **Catatan**: Field harus ada di `fields` atau `uploaders`

---

### 3. Schema Metadata (Optional)

Section ini berisi metadata database schema yang biasanya auto-generated dari model. Berguna untuk documentation dan tooling.

#### `schema.columns` (optional)
- **Tipe**: Array of Objects
- **Deskripsi**: Metadata lengkap semua kolom database (termasuk id, timestamps)
- **Format**:
  ```yaml
  schema:
    columns:
      - name: title                    # Nama kolom
        type: string                   # Rails type (string, integer, uuid, etc)
        sql_type: character varying    # SQL type dari database
        null: true                     # Apakah nullable? (true/false)
        default: null                  # Default value (optional)
        precision: null                # Untuk decimal/numeric (optional)
        scale: null                    # Untuk decimal/numeric (optional)
        limit: 255                     # Untuk string/varchar (optional)
  ```
- **Contoh lengkap**:
  ```yaml
  columns:
    - name: id
      type: uuid
      sql_type: uuid
      null: false
    - name: title
      type: string
      sql_type: character varying
      null: true
      limit: 255
    - name: price
      type: decimal
      sql_type: numeric
      null: false
      precision: 10
      scale: 2
      default: "0.0"
  ```
- **Digunakan untuk**: 
  - Documentation
  - Type validation
  - Code generation insights
- **Catatan**: Auto-generated dari `Model.columns`, tidak perlu di-set manual

#### `schema.foreign_keys` (optional)
- **Tipe**: Array of Objects atau `[]` (empty array)
- **Deskripsi**: Daftar foreign key constraints dari database
- **Format**:
  ```yaml
  foreign_keys:
    - column: account_id          # Nama kolom FK di table ini
      to_table: accounts          # Nama table yang direferensikan
    - column: user_id
      to_table: users
  ```
- **Atau kosong**:
  ```yaml
  foreign_keys: []
  ```
- **Digunakan untuk**: 
  - Documentation
  - Relationship validation
  - Code generation hints
- **Catatan**: Saat ini masih empty array, bisa diisi manual jika diperlukan

#### `schema.indexes` (optional)
- **Tipe**: Array of Objects atau `[]` (empty array)
- **Deskripsi**: Daftar database indexes
- **Format**:
  ```yaml
  indexes:
    - columns: ['account_id', 'status']    # Array kolom yang di-index
      unique: false                         # Apakah unique index?
    - columns: ['email']
      unique: true
  ```
- **Atau kosong**:
  ```yaml
  indexes: []
  ```
- **Digunakan untuk**: Documentation dan optimization hints
- **Catatan**: Saat ini masih empty array, bisa diisi manual jika diperlukan

#### `schema.enums` (optional)
- **Tipe**: Hash/Object atau `{}` (empty object)
- **Deskripsi**: Mapping enum values jika model menggunakan enum
- **Format**:
  ```yaml
  enums:
    status:                    # Nama kolom enum
      - draft                  # Value 1
      - published              # Value 2
      - archived               # Value 3
    priority:
      - low
      - medium
      - high
  ```
- **Atau kosong**:
  ```yaml
  enums: {}
  ```
- **Digunakan untuk**: 
  - Enum validation
  - Documentation
  - Form dropdown options
- **Catatan**: Bisa diisi manual jika model menggunakan enum

---

### 4. Controllers Configuration

Section ini mengkonfigurasi field-field yang digunakan di controller views.

#### `controllers.list_fields` (required)
- **Tipe**: Array of Strings atau `[]` (empty array)
- **Deskripsi**: Field yang ditampilkan di index/list view (table columns)
- **Contoh**:
  ```yaml
  list_fields:
    - title
    - status
    - published_at
    - created_at
  ```
- **Atau kosong**:
  ```yaml
  list_fields: []
  ```
- **Digunakan untuk**: Generate table columns di index page
- **Catatan**: Biasanya field penting yang ingin ditampilkan di list view

#### `controllers.show_fields` (required)
- **Tipe**: Array of Strings
- **Deskripsi**: Field yang ditampilkan di show/detail view. Biasanya termasuk semua field termasuk `id`, `created_at`, `updated_at`, dan uploaders.
- **Contoh**:
  ```yaml
  show_fields:
    - id
    - account_id
    - title
    - body
    - images
    - published_at
    - created_at
    - updated_at
  ```
- **Digunakan untuk**: Generate detail view di show page
- **Catatan**: Auto-generated dari semua columns + uploaders

#### `controllers.form_fields` (required)
- **Tipe**: Array of Objects atau `[]` (empty array)
- **Deskripsi**: Field yang ada di form create/edit beserta tipenya untuk generate form input yang sesuai
- **Format**:
  ```yaml
  form_fields:
    - name: title              # Nama field
      type: string             # Tipe input
    - name: body
      type: text               # textarea
    - name: published_at
      type: datetime           # datetime picker
    - name: images
      type: files              # multiple file upload
    - name: avatar
      type: file               # single file upload
  ```
- **Tipe yang didukung**:
  - `string` → text input
  - `text` → textarea
  - `integer` → number input
  - `uuid` → text input (UUID format)
  - `boolean` → checkbox
  - `datetime` → datetime picker
  - `date` → date picker
  - `file` → single file upload
  - `files` → multiple file upload
  - `decimal` → decimal input
  - `float` → float input
- **Atau kosong**:
  ```yaml
  form_fields: []
  ```
- **Digunakan untuk**: Generate form fields di create/edit page
- **Catatan**: Type menentukan jenis input HTML yang di-generate

---

### 5. Domains Configuration

Section ini mengkonfigurasi use case contracts dan repository filters untuk setiap action CRUD.

#### `domains.action_list` (required)
- **Deskripsi**: Konfigurasi untuk list/index action
- **Sub-keys**:
  
  **`use_case.contract`** (Array of Strings)
  - Dry-validation contract untuk filter/search parameters
  - Format: Array of string yang berisi Dry-validation rule
  - Contoh:
    ```yaml
    contract:
      - "optional(:title).maybe(:string)"
      - "optional(:status).maybe(:string)"
      - "optional(:published_at).maybe(:time)"
    ```
  - Atau kosong:
    ```yaml
    contract: []
    ```
  - **Rule format**: `"optional(:field_name).maybe(:type)"` untuk search fields
  - **Digunakan untuk**: Validasi input filter di use case
  
  **`repository.filters`** (Array of Objects)
  - Filter configuration untuk repository query
  - Format:
    ```yaml
    filters:
      - { field: 'title', type: 'search' }      # Search/ILIKE filter
      - { field: 'status', type: 'exact' }      # Exact match filter
      - { field: 'published_at', type: 'date' }  # Date range filter
    ```
  - Atau kosong:
    ```yaml
    filters: []
    ```
  - **Filter types**: 
    - `search` → ILIKE/LIKE search
    - `exact` → Exact match (=)
    - `date` → Date range
  - **Digunakan untuk**: Generate repository filter logic

#### `domains.action_fetch_by_id` (required)
- **Deskripsi**: Konfigurasi untuk show/detail action
- **Sub-keys**:
  
  **`use_case.contract`** (Array of Strings)
  - Dry-validation contract yang **wajib** berisi `id` dan `resource_owner_id`
  - Format:
    ```yaml
    contract:
      - "required(:id).filled(:string)"
      - "required(:account_id).filled(:string)"
    ```
  - **Digunakan untuk**: Validasi parameter id dan resource_owner_id
  - **Catatan**: Selalu required, tidak bisa optional

#### `domains.action_create` (required)
- **Deskripsi**: Konfigurasi untuk create action
- **Sub-keys**:
  
  **`use_case.contract`** (Array of Strings)
  - Dry-validation contract untuk create. Field dengan `null: false` menjadi `required`, yang lain `optional`
  - Format:
    ```yaml
    contract:
      - "required(:account_id).filled(:string)"
      - "required(:title).filled(:string)"
      - "optional(:body).maybe(:string)"
      - "optional(:published_at).maybe(:time)"
    ```
  - Atau kosong (jika tidak ada fields):
    ```yaml
    contract: []
    ```
  - **Rule format**: 
    - Required: `"required(:field_name).filled(:type)"`
    - Optional: `"optional(:field_name).maybe(:type)"`
  - **Type mapping**:
    - `uuid`, `string`, `text` → `:string`
    - `integer` → `:integer`
    - `boolean` → `:bool`
    - `datetime` → `:time`
    - `date` → `:date`
    - `decimal`, `float` → `:decimal`, `:float`
    - `upload` → `Types::File`
  - **Digunakan untuk**: Validasi input create di use case
  - **Catatan**: `resource_owner_id` selalu required jika ada

#### `domains.action_update` (required)
- **Deskripsi**: Konfigurasi untuk update action
- **Sub-keys**:
  
  **`use_case.contract`** (Array of Strings)
  - Dry-validation contract yang **wajib** berisi `id` dan `resource_owner_id`, field lain optional
  - Format:
    ```yaml
    contract:
      - "required(:id).filled(:string)"
      - "required(:account_id).filled(:string)"
      - "optional(:title).maybe(:string)"
      - "optional(:body).maybe(:string)"
    ```
  - **Digunakan untuk**: Validasi input update di use case
  - **Catatan**: Semua field selain `id` dan `resource_owner_id` adalah optional (partial update)

#### `domains.action_destroy` (required)
- **Deskripsi**: Konfigurasi untuk destroy/delete action
- **Sub-keys**:
  
  **`use_case.contract`** (Array of Strings)
  - Dry-validation contract yang **wajib** berisi `id` dan `resource_owner_id`
  - Format:
    ```yaml
    contract:
      - "required(:id).filled(:string)"
      - "required(:account_id).filled(:string)"
    ```
  - **Digunakan untuk**: Validasi parameter delete di use case
  - **Catatan**: Hanya butuh id dan resource_owner_id untuk authorization

---

### 6. Entity Configuration

Section ini mengkonfigurasi entity builder yang memetakan ActiveRecord ke Domain Entity.

#### `entity.skipped_fields` (required)
- **Tipe**: Array of Strings
- **Deskripsi**: Field yang di-skip saat mapping dari ActiveRecord ke Entity (tidak di-copy ke entity)
- **Default**:
  ```yaml
  skipped_fields:
    - id
    - created_at
    - updated_at
    - type  # jika menggunakan STI (Single Table Inheritance)
  ```
- **Digunakan untuk**: Generate entity builder yang skip field tertentu
- **Catatan**: Field ini biasanya di-handle secara khusus oleh entity, tidak perlu di-copy dari AR

#### `entity.db_attributes` (required)
- **Tipe**: Array of Strings atau `[]` (empty array)
- **Deskripsi**: Field database yang di-map ke entity attributes (di-copy dari ActiveRecord)
- **Contoh**:
  ```yaml
  db_attributes:
    - account_id
    - title
    - body
    - published_at
    - user_id
  ```
- **Atau kosong**:
  ```yaml
  db_attributes: []
  ```
- **Digunakan untuk**: Generate entity attributes dari database columns
- **Catatan**: Biasanya semua field dari `fields` section, tidak termasuk uploaders (uploaders di-handle terpisah)

---

## Type Mapping Reference

Berikut mapping tipe database ke Dry-validation types:

| Database Type | Dry-Validation Type | Entity Type |
|--------------|---------------------|-------------|
| `uuid` | `:string` | `Types::Strict::String` |
| `string` | `:string` | `Types::Strict::String` |
| `text` | `:string` | `Types::Strict::String` |
| `integer` | `:integer` | `Types::Strict::Integer` |
| `boolean` | `:bool` | `Types::Strict::Bool` |
| `float` | `:float` | `Types::Strict::Float` |
| `decimal` | `:decimal` | `Types::Strict::Decimal` |
| `date` | `:date` | `Types::Strict::Date` |
| `datetime` | `:time` | `Types::Strict::Time` |
| `upload` | `Types::File` | `Types::File` |

---

## Formatting Rules

1. **Indentasi**: Gunakan **2 spasi** per level indentasi
2. **Empty Arrays**: Tulis inline `[]` bukan multi-line
3. **Empty Objects**: Tulis inline `{}` bukan multi-line
4. **Strings**: Gunakan quotes jika mengandung special characters
5. **Comments**: Gunakan `#` untuk komentar inline

**Contoh yang benar**:
```yaml
uploaders: []
foreign_keys: []
enums: {}
```

**Contoh yang salah**:
```yaml
uploaders:
  []

foreign_keys:
  []
```

---

## Workflow Penggunaan

1. **Generate Structure File**:
   ```bash
   rails generate rider_kick:structure Models::Article \
     actor:owner \
     resource_owner:account \
     resource_owner_id:account_id \
     uploaders:images,assets \
     search_able:title,body
   ```

2. **Edit Structure File** (optional):
   - Edit `db/structures/articles_structure.yaml` sesuai kebutuhan
   - Tambah/edit fields, uploaders, search_able, dll

3. **Generate/Regenerate Code**:
   ```bash
   rails generate rider_kick:scaffold articles
   ```
   Atau jika sudah ada:
   ```bash
   rails generate rider_kick:scaffold articles --force
   ```

4. **Code akan di-generate sesuai structure.yaml**:
   - Use cases dengan contract validation
   - Repositories dengan filters
   - Entities dengan attributes
   - Controllers dengan actions
   - Views dengan fields

---

## Best Practices

1. **Jangan edit manual jika tidak perlu**: Structure file biasanya auto-generated dari model, edit hanya jika ada customisasi khusus

2. **Keep it in sync**: Setelah edit structure.yaml, selalu regenerate code dengan scaffold generator

3. **Version control**: Commit structure.yaml ke git untuk tracking perubahan

4. **Documentation**: Gunakan comments di YAML untuk menjelaskan konfigurasi khusus

5. **Validation**: Pastikan semua required fields terisi sebelum generate code

---

## Troubleshooting

### Error: Missing required setting
- **Penyebab**: Required parameter tidak disediakan saat generate
- **Solusi**: Pastikan `actor`, `resource_owner`, dan `resource_owner_id` selalu disediakan

### Error: Model not found
- **Penyebab**: Model class tidak ditemukan
- **Solusi**: Pastikan model sudah dibuat dan namespace benar

### Error: Invalid YAML format
- **Penyebab**: Format YAML tidak valid (indentasi salah, syntax error)
- **Solusi**: Validasi YAML dengan YAML parser atau editor yang support YAML

### Contract tidak sesuai
- **Penyebab**: Field di contract tidak match dengan database schema
- **Solusi**: Regenerate structure dari model terbaru atau update manual

---

## Contoh Use Cases

### Contoh 1: Simple Blog Post
```yaml
model: Models::Post
resource_name: posts
resource_owner_id: account_id
resource_owner: account
actor: user
actor_id: user_id

fields:
  - account_id
  - title
  - content
  - published

uploaders: []

search_able:
  - title
```

### Contoh 2: Product dengan Multiple Images
```yaml
model: Models::Product
resource_name: products
resource_owner_id: store_id
resource_owner: store
actor: merchant
actor_id: merchant_id

fields:
  - store_id
  - name
  - description
  - price
  - sku

uploaders:
  - { name: 'images', type: 'multiple' }
  - { name: 'thumbnail', type: 'single' }

search_able:
  - name
  - sku
```

### Contoh 3: Document dengan Attachments
```yaml
model: Models::Document
resource_name: documents
resource_owner_id: organization_id
resource_owner: organization
actor: user
actor_id: user_id

fields:
  - organization_id
  - title
  - content
  - category

uploaders:
  - { name: 'attachments', type: 'multiple' }
  - { name: 'cover_image', type: 'single' }

search_able:
  - title
  - content
```

---

## Referensi

- [RiderKick Generator Documentation](./README.md)
- [Dry-Validation Documentation](https://dry-rb.org/gems/dry-validation/)
- [Rails Generators Guide](https://guides.rubyonrails.org/generators.html)


