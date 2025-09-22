# frozen_string_literal: true

# Stub sederhana untuk Models::User agar generator bisa jalan tanpa DB
Object.send(:remove_const, :Models) if Object.const_defined?(:Models)
module Models; end

class Models::User
  Column = Struct.new(:name, :type, :sql_type, :null, :default, :precision, :scale, :limit)
  private_constant :Column
  def self.columns
    [
      Column.new("id", :uuid),
      Column.new("name", :string),
      Column.new("price", :decimal),
      Column.new("created_at", :datetime),
      Column.new("updated_at", :datetime)
    ]
  end

  def self.columns_hash
    columns.to_h { |c| [c.name.to_s, Struct.new(:type).new(c.type)] }
  end
end
