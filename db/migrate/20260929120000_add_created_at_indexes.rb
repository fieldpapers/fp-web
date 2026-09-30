class AddCreatedAtIndexes < ActiveRecord::Migration[7.2]
  def change
    add_index :atlases, :created_at
    add_index :snapshots, :created_at
  end
end
