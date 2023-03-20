class DropDecodingJsonFromSnapshots < ActiveRecord::Migration[4.2]
  def change
    remove_column :snapshots, :decoding_json
  end
end
