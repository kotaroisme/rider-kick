# Analisis Conditional Filtering - Instance Variables

## Instance Variables yang Tersedia di Scaffold Generator

### 1. Resource Owner ID Flags (10 instance variables)
- `@has_resource_owner_id_in_list_contract`
- `@has_resource_owner_id_in_fetch_by_id_contract`
- `@has_resource_owner_id_in_create_contract`
- `@has_resource_owner_id_in_update_contract`
- `@has_resource_owner_id_in_destroy_contract`

### 2. Actor ID Flags (10 instance variables)
- `@has_actor_id_in_list_contract`
- `@has_actor_id_in_fetch_by_id_contract`
- `@has_actor_id_in_create_contract`
- `@has_actor_id_in_update_contract`
- `@has_actor_id_in_destroy_contract`

### 3. Helper Methods
- `has_resource_owner_id_in_contract?(action)` - untuk template
- `has_actor_id_in_contract?(action)` - untuk template

## Status Penggunaan di Template

### ✅ Template Repository (Sudah Benar)
1. **list.rb.tt** ✅
   - Menggunakan: `@has_resource_owner_id_in_list_contract`
   
2. **fetch_by_id.rb.tt** ✅
   - Menggunakan: `@has_resource_owner_id_in_fetch_by_id_contract`
   
3. **update.rb.tt** ✅
   - Menggunakan: `@has_resource_owner_id_in_update_contract`
   
4. **destroy.rb.tt** ✅
   - Menggunakan: `@has_resource_owner_id_in_destroy_contract`
   
5. **create.rb.tt** ✅
   - Tidak menggunakan filter (benar, karena create tidak perlu filter)

### ✅ Template Use Case (Sudah Benar)
1. **list.rb.tt** ✅
   - Tidak menambahkan resource_owner_id secara eksplisit (mengandalkan contract YAML)
   
2. **fetch_by_id.rb.tt** ✅
   - Skip resource_owner_id jika sudah ada di contract YAML
   
3. **update.rb.tt** ✅
   - Skip resource_owner_id jika sudah ada di contract YAML
   
4. **destroy.rb.tt** ✅
   - Skip resource_owner_id jika sudah ada di contract YAML
   
5. **create.rb.tt** ✅
   - Skip resource_owner_id jika sudah ada di contract YAML

### ✅ Template Repository Spec (Sudah Benar)
1. **list_spec.rb.tt** ✅
   - Menggunakan: `@has_resource_owner_id_in_list_contract` di semua tempat
   
2. **fetch_by_id_spec.rb.tt** ✅
   - Menggunakan: `@has_resource_owner_id_in_fetch_by_id_contract`
   
3. **update_spec.rb.tt** ✅
   - Menggunakan: `@has_resource_owner_id_in_update_contract`
   
4. **destroy_spec.rb.tt** ✅
   - Menggunakan: `@has_resource_owner_id_in_destroy_contract`
   
5. **create_spec.rb.tt** ✅
   - Menggunakan: `@resource_owner_id.present?` (benar, karena create tidak menggunakan filter)

### ✅ Template Use Case Spec (Sudah Benar)
1. **list_spec.rb.tt** ✅
   - Menggunakan: `@has_resource_owner_id_in_list_contract`
   
2. **fetch_by_id_spec.rb.tt** ✅
   - Menggunakan: `@has_resource_owner_id_in_fetch_by_id_contract`
   
3. **update_spec.rb.tt** ✅
   - Menggunakan: `@has_resource_owner_id_in_update_contract`
   
4. **destroy_spec.rb.tt** ✅
   - Menggunakan: `@has_resource_owner_id_in_destroy_contract`
   
5. **create_spec.rb.tt** ✅
   - Menggunakan: `@resource_owner_id.present?` (benar, karena create tidak menggunakan filter)

## Kesimpulan

✅ **SEMUA SUDAH BENAR**

Semua instance variable sudah:
1. ✅ Di-set dengan benar di `setup_repository_variables`
2. ✅ Digunakan dengan benar di template repository untuk conditional filtering
3. ✅ Digunakan dengan benar di template spec untuk conditional test setup
4. ✅ Template use case sudah menggunakan skip logic yang benar
5. ✅ Helper methods sudah tersedia untuk akses yang lebih mudah

## Catatan Penting

1. **Create Action**: Tidak menggunakan filter di repository, jadi tidak perlu conditional check untuk filter. Namun tetap menggunakan `@resource_owner_id.present?` untuk skip field di valid_params.

2. **Actor ID**: Instance variable sudah tersedia tapi belum digunakan di template. Jika diperlukan di masa depan, bisa langsung digunakan dengan pattern yang sama seperti resource_owner_id.

3. **Pattern Consistency**: Semua template mengikuti pattern yang sama:
   - Repository: `@resource_owner_id.present? && @has_resource_owner_id_in_*_contract`
   - Spec: `@resource_owner_id.present? && @has_resource_owner_id_in_*_contract`
   - Use Case: Skip jika sudah ada di contract YAML


