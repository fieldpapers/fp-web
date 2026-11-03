# Fails atlases and snapshots that have been processing for too long, e.g.
# because their job crashed or was lost. If such a job later finishes, the
# record stays failed.
class ReapStuckJob < ApplicationJob
  MAX_AGE = 2.hours

  def perform
    now = Time.current

    [Atlas, Snapshot].each do |model|
      count = model.unscoped.pending.where(created_at: ...MAX_AGE.ago).update_all(failed_at: now, updated_at: now)
      logger.warn("Failed #{count} stuck #{model.name.pluralize.downcase}") if count > 0
    end
  end
end
