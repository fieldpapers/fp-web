class ConvertSnapshotFailedToTimestamp < ActiveRecord::Migration[4.2]
  def up
    change_table(:snapshots) do |t|
      t.datetime :failed_at
    end

    execute <<-EOQ
      UPDATE snapshots
      SET failed_at=decoded_at
      WHERE failed=true
    EOQ

    remove_column :snapshots, :failed
  end
end
