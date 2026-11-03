require 'test_helper'

class ReapStuckJobTest < ActiveJob::TestCase
  test "fails atlases and snapshots that have been pending too long" do
    stuck_atlas = create_atlas(rows: 1, cols: 1)
    new_atlas = create_atlas(rows: 1, cols: 1)
    done_atlas = create_atlas(rows: 1, cols: 1)
    done_atlas.mark_complete!(pdf_url: "https://example.com/atlas.pdf")
    stuck_snapshot = create_pending_snapshot("stuck001")
    new_snapshot = create_pending_snapshot("new00001")

    [stuck_atlas, done_atlas, stuck_snapshot].each { |r| r.update_column(:created_at, 3.hours.ago) }

    ReapStuckJob.perform_now

    assert_equal [:failed, :pending, :complete], [stuck_atlas, new_atlas, done_atlas].map { |a| a.reload.status }
    assert_equal [:failed, :pending], [stuck_snapshot, new_snapshot].map { |s| s.reload.status }
  end
end
