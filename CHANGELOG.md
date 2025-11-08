## [Unreleased]

### Added
- **Enhanced List Repository Spec Tests**: Comprehensive test coverage untuk list repository
  - **Search Tests**: Auto-generate test untuk setiap field di `search_able` array
    - Test filtering by each searchable field
    - Test case-insensitive search
    - Test empty result when no matches
  - **Pagination Tests**: Detailed pagination testing
    - Test dengan page 3 dan per_page 3 (sesuai requirement)
    - Test empty result untuk page beyond available pages
    - Test per_page parameter handling
    - Verify pagy metadata (count, page, per_page, pages)
  - **Enhanced Expectations**: 
    - Verify response structure (Array, Hash)
    - Verify meta pagination data
    - Verify sorting (default descending, custom ascending)
    - Verify resource owner filtering dengan count verification
    - Test empty state handling
  - **Quality Improvements**:
    - Comprehensive assertions dengan `:aggregate_failures`
    - Proper test data setup untuk each scenario
    - Edge case testing (empty results, beyond pages, etc.)
    - Clear test descriptions dan comments

- **FactoryBot Factory Generator**: Generator baru untuk membuat FactoryBot factories
  - Command: `rails generate rider_kick:factory Models::Article scope:core`
  - **NEW**: `--static` option untuk generate nilai static (e.g., `full_name { 'John Doe' }` instead of `full_name { Faker::Name.name }`)
    - Berguna untuk test data yang konsisten dan reproducible
    - Pre-evaluate semua Faker expressions saat generation time
    - Perfect untuk debugging atau custom values
    - **Exception:** Time fields (datetime/timestamp/time) tetap menggunakan `Time.zone.now` bahkan dengan `--static`
  - Otomatis skip semua kolom *_id (foreign keys)
  - Smart Faker value generation berdasarkan tipe kolom dan nama field
  - Support untuk scope/namespace factories (e.g., `spec/factories/core/article.rb`)
  - Type-aware Faker generation:
    - String fields dengan nama spesial (email, name, phone, url, etc.)
    - Text fields untuk description/content/body → paragraphs
    - Decimal/price/amount → Commerce.price
    - Boolean → random true/false
    - Date → Faker date
    - DateTime/Timestamp/Time → `Time.zone.now` (untuk consistency dan timezone awareness)
    - JSON/JSONB → hash structure
    - Dan lainnya...
  - Dokumentasi lengkap di README.md dan FACTORY_GENERATOR.md
  
- **Automatic RSpec Generation**: Generator sekarang otomatis men-generate spec files untuk semua code files
  - Use case specs dengan coverage untuk validation, success, dan failure scenarios
  - Repository specs dengan coverage untuk CRUD operations, pagination, dan filtering
  - Builder specs dengan comprehensive coverage:
    - Test `acts_as_builder_for_entity` behavior
    - Test `attributes_for_entity` method (jika ada uploaders)
    - Verify all entity attributes exist (keys must exist, values can be nil)
    - Test model-to-entity transformation dan uploader handling
  - Entity specs dengan coverage untuk structure validation dan immutability
  - Spec files ditempatkan sejajar dengan code files untuk kemudahan navigasi
  - Support penuh untuk resource_owner_id, uploaders (single & multiple), dan search filters
  - Builder specs menggunakan `ClassStubber::Model` untuk test data yang lebih sederhana
  - Dokumentasi lengkap tersedia di SPEC_GENERATION.md
  
- **ClassStubber Helper**: Helper baru untuk mempermudah mocking di specs
  - `ClassStubber::Model` - Simple hash-based model stub
  - `ClassStubber::ActiveStorageAttachment` - Helper untuk mock Active Storage attachments
  - Type-aware value generation - otomatis gunakan nilai yang sesuai dengan tipe field:
    - `datetime`/`timestamp`/`time` → `Time.current`
    - `date` → `Date.current`
    - `boolean` → `true`/`false`
    - `integer`/`bigint` → `123`
    - `decimal`/`float` → `123.45`
  - Smart field filtering - otomatis skip uploader fields dari entity_db_fields untuk menghindari duplikasi
  - Otomatis di-generate saat `rider_kick:clean_arch --setup`
  - File template: `spec/support/class_stubber.rb`

- **Documentation**: 
  - SPEC_GENERATION.md - Comprehensive guide untuk RSpec generation
  - UPGRADE.md - Migration guide untuk existing projects

## [0.1.0] - 2024-09-01

- Initial release
