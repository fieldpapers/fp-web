require 'test_helper'

class ProcessSnapshotJobTest < ActiveJob::TestCase
  def href(atlas, page_number)
    page = atlas.pages.find_by!(page_number: page_number)
    "https://fieldpapers.org/atlases/#{atlas.slug}/#{page_number}?bbox=#{page.bbox.join(",")}"
  end

  test "georeferences the image as the page in its QR code" do
    atlas = create_atlas(rows: 2, cols: 2)
    atlas.update_column(:private, true)
    page = atlas.pages.find_by!(page_number: "B1")
    snapshot = create_pending_snapshot("snap0001")

    georeference = ->(s, p) {
      assert_equal [snapshot, page, atlas], [s, p, p.atlas]
      "https://example.com/snap0001.tiff"
    }

    stub_fp_tasks(decode_qr: ->(*) { href(atlas, "B1") }, georeference: georeference) do
      ProcessSnapshotJob.perform_now(snapshot.id)
    end

    snapshot.reload
    assert snapshot.complete?
    assert_equal page, snapshot.page
    assert_equal href(atlas, "B1"), snapshot.page_url
    assert_equal "https://example.com/snap0001.tiff", snapshot.geotiff_url
    assert_equal page.bbox, snapshot.bbox
    assert_equal page.zoom, snapshot.zoom
    assert snapshot.private
    assert_equal 1, snapshot.progress
  end

  test "fails snapshots whose QR code isn't a known page" do
    snapshot = create_pending_snapshot("snap0001")

    stub_fp_tasks(decode_qr: ->(*) { "https://example.com/atlases/abc/A1" }, georeference: ->(*) { flunk }) do
      ProcessSnapshotJob.perform_now(snapshot.id)
    end

    snapshot.reload
    assert snapshot.failed?
    assert_equal "https://example.com/atlases/abc/A1", snapshot.page_url
  end

  test "fails snapshots without a QR code" do
    snapshot = create_pending_snapshot("snap0001")

    stub_fp_tasks(decode_qr: ->(*) { raise fp_tasks_error(Faraday::ClientError, 422) }) do
      ProcessSnapshotJob.perform_now(snapshot.id)
    end

    assert snapshot.reload.failed?
    assert_no_enqueued_jobs
  end
end
