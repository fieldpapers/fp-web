# A record processed by a background job. It is pending until exactly one of
# its completion timestamp (named by `completed_at_column`) or `failed_at` is
# set. Those transitions are conditional updates, so the first caller wins and
# late or duplicate work can't change a finished record.
module Processable
  extend ActiveSupport::Concern

  included do
    scope :pending, -> { where(completed_at_column => nil, failed_at: nil) }
  end

  class_methods do
    def completed_at_column(column = nil)
      @completed_at_column = column if column
      @completed_at_column
    end
  end

  def status
    if failed_at
      :failed
    elsif self[self.class.completed_at_column]
      :complete
    else
      :pending
    end
  end

  def complete?
    status == :complete
  end

  def incomplete?
    status == :pending
  end

  def failed?
    status == :failed
  end

  # Marks the record complete, also setting attrs, unless it has already
  # finished. Returns whether this call completed it.
  def mark_complete!(**attrs)
    finish!(self.class.completed_at_column, attrs)
  end

  # Marks the record failed unless it has already finished. Returns whether
  # this call failed it.
  def mark_failed!
    finish!(:failed_at, {})
  end

  private

  def finish!(column, attrs)
    now = Time.current
    attrs = attrs.merge(column => now, updated_at: now)
    won = self.class.unscoped.pending.where(id: id).update_all(attrs) == 1
    reload
    won
  end
end
