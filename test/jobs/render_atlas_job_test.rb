require 'test_helper'

class RenderAtlasJobTest < ActiveJob::TestCase
  def render
    ->(page) { "https://example.com/#{page.page_number}.pdf" }
  end

  test "renders each page, then merges them in order" do
    atlas = create_atlas(rows: 1, cols: 2)
    rendered = []
    render = ->(page) { rendered << page.page_number; "https://example.com/#{page.page_number}.pdf" }
    merge = ->(_, urls) { assert_equal %w[i A1 A2].map { |n| "https://example.com/#{n}.pdf" }, urls; "https://example.com/atlas.pdf" }

    stub_fp_tasks(render_index: render, render_page: render, merge_pages: merge) do
      RenderAtlasJob.perform_now(atlas.id)
    end

    atlas.reload
    assert_equal %w[i A1 A2], rendered
    assert atlas.complete?
    assert_equal "https://example.com/atlas.pdf", atlas.pdf_url
    assert_equal 1, atlas.progress
    assert atlas.pages.all?(&:composed_at)
    assert_equal "https://example.com/A2.pdf", atlas.pages.last.pdf_url
  end

  test "renders private atlases" do
    atlas = create_atlas(rows: 1, cols: 1)
    atlas.update_column(:private, true)

    stub_fp_tasks(render_page: render, merge_pages: ->(*) { "https://example.com/atlas.pdf" }) do
      RenderAtlasJob.perform_now(atlas.id)
    end

    assert atlas.reload.complete?
  end

  test "skips pages that were already rendered" do
    atlas = create_atlas(rows: 1, cols: 2)
    atlas.pages.where(page_number: %w[i A1]).update_all(pdf_url: "https://example.com/old.pdf", composed_at: Time.current)
    rendered = []

    stub_fp_tasks(render_index: ->(*) { flunk }, render_page: ->(page) { rendered << page.page_number; "x" },
                  merge_pages: ->(*) { "https://example.com/atlas.pdf" }) do
      RenderAtlasJob.perform_now(atlas.id)
    end

    assert_equal %w[A2], rendered
    assert atlas.reload.complete?
  end

  test "fails the atlas without retrying when fp-tasks rejects a page" do
    atlas = create_atlas(rows: 1, cols: 1)

    stub_fp_tasks(render_page: ->(*) { raise fp_tasks_error(Faraday::ClientError, 422) }) do
      RenderAtlasJob.perform_now(atlas.id)
    end

    assert atlas.reload.failed?
    assert_no_enqueued_jobs
  end

  test "retries server errors, then fails the atlas" do
    atlas = create_atlas(rows: 1, cols: 1)
    attempts = 0

    stub_fp_tasks(render_page: ->(*) { attempts += 1; raise fp_tasks_error(Faraday::ServerError, 500) }) do
      # performs retries as they're enqueued
      perform_enqueued_jobs { RenderAtlasJob.perform_later(atlas.id) }
    end

    assert_equal 5, attempts
    assert atlas.reload.failed?
  end

  test "retries timeouts" do
    atlas = create_atlas(rows: 1, cols: 1)

    stub_fp_tasks(render_page: ->(*) { raise Faraday::TimeoutError }) do
      RenderAtlasJob.perform_now(atlas.id)
    end

    assert atlas.reload.incomplete?
    assert_enqueued_jobs 1, only: RenderAtlasJob
  end

  test "does nothing for atlases that already failed" do
    atlas = create_atlas(rows: 1, cols: 1)
    atlas.mark_failed!

    stub_fp_tasks(render_page: ->(*) { flunk }) do
      RenderAtlasJob.perform_now(atlas.id)
    end

    assert atlas.reload.failed?
  end
end
