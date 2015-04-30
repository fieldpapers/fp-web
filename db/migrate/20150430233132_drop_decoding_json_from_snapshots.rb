class DropDecodingJsonFromSnapshots < ActiveRecord::Migration
  def change
    remove_column :snapshots, :decoding_json
  end
end
