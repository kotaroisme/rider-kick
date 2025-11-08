# Upgrade Guide

## Upgrading to Version with RSpec Generation

Jika Anda sudah menggunakan rider-kick sebelumnya dan ingin upgrade ke versi dengan automatic RSpec generation, ikuti langkah-langkah berikut:

### 1. Update Gem

```bash
bundle update rider-kick
```

### 2. Add ClassStubber Helper

Generator RSpec baru membutuhkan `ClassStubber` helper. Ada dua cara untuk menambahkannya:

#### Option A: Copy dari Template (Recommended)

```bash
# Copy file class_stubber.rb dari gem
cp $(bundle show rider-kick)/lib/generators/rider_kick/templates/spec/support/class_stubber.rb spec/support/

# Atau manual download dari GitHub
curl -o spec/support/class_stubber.rb https://raw.githubusercontent.com/.../class_stubber.rb
```

#### Option B: Manual Setup

Buat file `spec/support/class_stubber.rb` dengan konten berikut:

```ruby
# frozen_string_literal: true

module ClassStubber
  class Model
    def initialize(attributes = {})
      @attributes = attributes.transform_keys(&:to_s)
    end

    def method_missing(method_name, *args, &block)
      key = method_name.to_s
      if @attributes.key?(key)
        @attributes[key]
      else
        super
      end
    end

    def respond_to_missing?(method_name, include_private = false)
      @attributes.key?(method_name.to_s) || super
    end
  end

  class ActiveStorageAttachment
    def self.new_single(url)
      ActiveStorageAttachmentSingle.new(url)
    end

    def self.new_multiple(urls = [])
      ActiveStorageAttachmentMultiple.new(urls)
    end
  end

  class ActiveStorageAttachmentSingle
    attr_reader :url

    def initialize(url)
      @url = url
    end

    def attached?
      !@url.nil?
    end
  end

  class ActiveStorageAttachmentMultiple
    include Enumerable
    attr_reader :urls

    def initialize(urls = [])
      @urls = urls.compact
      @attachments = @urls.map { |url| ActiveStorageAttachmentSingle.new(url) }
    end

    def attached?
      @urls.any?
    end

    def each(&block)
      @attachments.each(&block)
    end

    def map(&block)
      @attachments.map(&block)
    end

    def size
      @attachments.size
    end
  end
end
```

### 3. Update rails_helper.rb

Pastikan `spec/rails_helper.rb` Anda meng-include ClassStubber:

```ruby
# spec/rails_helper.rb

# Load support files
Dir[Rails.root.join('spec', 'support', '**', '*.rb')].sort.each { |f| require f }

RSpec.configure do |config|
  # ... existing configuration ...
  
  # Add this line if not exists
  config.include ClassStubber
end
```

### 4. Regenerate Specs (Optional)

Jika Anda ingin men-generate spec files untuk scaffold yang sudah ada:

```bash
# Regenerate scaffold untuk resource yang sudah ada
bin/rails generate rider_kick:scaffold articles

# Generator akan create/update spec files
```

### 5. Verify Setup

Test bahwa ClassStubber bekerja dengan baik:

```bash
# Run existing specs
bundle exec rspec

# Generate new scaffold dengan specs
bin/rails g model models/test_model name:string
bin/rails generate rider_kick:structure Models::TestModel actor:user
bin/rails generate rider_kick:scaffold test_models

# Check generated spec files
ls app/domains/core/builders/test_model_spec.rb
ls app/domains/core/entities/test_model_spec.rb
```

## Breaking Changes

### Builder Specs Format

**Old Format (masih bekerja, tapi deprecated):**
```ruby
let(:article) { instance_double(Models::Article) }

before do
  allow(article).to receive(:id).and_return('test-id-123')
  allow(article).to receive(:title).and_return('title_value')
end
```

**New Format (recommended):**
```ruby
let(:article) do
  ClassStubber::Model.new(
    'id' => 'test-id-123',
    'title' => 'title_value'
  )
end
```

Jika Anda punya custom builder specs, Anda bisa tetap menggunakan format lama atau migrate ke format baru secara bertahap.

## Migration Path

### For Existing Projects

1. **Keep existing specs as-is** - Format lama masih bekerja
2. **New specs use ClassStubber** - Generator akan create specs dengan format baru
3. **Gradually migrate** - Update existing specs ke format baru ketika Anda edit mereka

### For New Projects

Tidak ada migration yang diperlukan. Semua akan ter-setup otomatis dengan:

```bash
bin/rails generate rider_kick:clean_arch --setup
```

## FAQ

### Q: Apakah saya harus update semua existing specs?
**A:** Tidak. Format lama dengan `instance_double` masih bekerja. Update hanya jika Anda mau.

### Q: Bagaimana jika saya sudah punya spec/support/class_stubber.rb sendiri?
**A:** Generator tidak akan overwrite file yang sudah ada. Anda bisa merge manual atau rename file Anda terlebih dahulu.

### Q: Apakah ini memerlukan gem tambahan?
**A:** Tidak. ClassStubber adalah pure Ruby helper yang sudah included.

### Q: Generated specs gagal dengan error ClassStubber
**A:** Pastikan:
1. File `spec/support/class_stubber.rb` ada
2. `rails_helper.rb` include ClassStubber
3. Restart spring jika menggunakan: `spring stop`

## Rollback

Jika Anda ingin rollback ke versi sebelumnya:

```bash
# Update Gemfile
gem 'rider-kick', '~> 0.0.13'  # version sebelum RSpec generation

# Bundle install
bundle install

# Remove ClassStubber (optional)
rm spec/support/class_stubber.rb
```

## Support

Jika Anda mengalami masalah saat upgrade, silakan:
1. Check [SPEC_GENERATION.md](SPEC_GENERATION.md) untuk dokumentasi lengkap
2. Check issue tracker di GitHub
3. Create new issue dengan detail error message


