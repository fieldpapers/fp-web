# Marks atlases and snapshots that never finished processing as failed. Their
# work was lost by fp-tasks' old in-memory queue, so they would otherwise stay
# pending forever. Records created in the last day are left for the reaper
# (ReapStuckJob).
class FailStuckAtlasesAndSnapshots < ActiveRecord::Migration[7.2]
  def up
    { atlases: :composed_at, snapshots: :decoded_at }.each do |table, column|
      execute <<~SQL
        UPDATE #{table} SET failed_at = now(), updated_at = now()
        WHERE #{column} IS NULL AND failed_at IS NULL
          AND (created_at IS NULL OR created_at < now() - interval '1 day')
      SQL
    end
  end

  def down
  end
end
