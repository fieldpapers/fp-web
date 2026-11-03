class AddPageIdIndexToSnapshots < ActiveRecord::Migration[7.0]
  def change
    add_index :snapshots, :page_id
  end
end
