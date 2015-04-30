class AddBoundsToSnapshots < ActiveRecord::Migration
  def change
    change_table(:snapshots) do |t|
      t.float :west
      t.float :south
      t.float :east
      t.float :north
      t.integer :zoom
    end
  end
end
