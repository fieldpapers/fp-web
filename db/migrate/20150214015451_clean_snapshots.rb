class CleanSnapshots < ActiveRecord::Migration[4.2]
  def change
    rename_table :scans, :snapshots

    execute("ALTER TABLE snapshots CHANGE created created_at TIMESTAMP")
    execute("ALTER TABLE snapshots CHANGE decoded decoded_at TIMESTAMP")

    change_table(:snapshots) do |t|
      t.datetime :updated_at
    end

    execute("DROP VIEW IF EXISTS new_snapshots")
  end
end
