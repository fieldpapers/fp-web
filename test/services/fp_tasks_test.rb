require 'test_helper'

class FpTasksTest < ActiveSupport::TestCase
  # Runs block with FpTasks' requests going to Faraday test stubs
  def with_stubs
    stubs = Faraday::Adapter::Test::Stubs.new
    connection = FpTasks.send(:connection).dup
    connection.builder.adapter(:test, stubs)
    FpTasks.stub(:connection, connection) { yield stubs }
    stubs.verify_stubbed_calls
  end

  def json(body, status: 200)
    [status, { "Content-Type" => "application/json" }, body.to_json]
  end

  test "render_index" do
    atlas = create_atlas(rows: 1, cols: 2)
    atlas.update_column(:text, nil)
    page = atlas.pages.first

    with_stubs do |stubs|
      stubs.post("/render_index") do |env|
        assert_equal 90, env.request.timeout
        assert_equal({
          "slug" => atlas.slug, "page_number" => "i", "bbox" => page.bbox, "zoom" => page.zoom,
          "provider" => page.provider, "paper_size" => "letter", "orientation" => "landscape",
          "layout" => "full-page", "text" => "", "title" => "Untitled",
          "atlas_bbox" => atlas.bbox, "cols" => 2, "rows" => 1,
        }, JSON.parse(env.request_body))
        json({ pdf_url: "https://example.com/index.pdf" })
      end

      assert_equal "https://example.com/index.pdf", FpTasks.render_index(page)
    end
  end

  test "rejected input raises a client error" do
    snapshot = create_pending_snapshot("snap0001")

    with_stubs do |stubs|
      stubs.post("/decode_qr") { json({ detail: "no QR code found" }, status: 422) }

      error = assert_raises(Faraday::ClientError) { FpTasks.decode_qr(snapshot) }
      assert_equal({ "detail" => "no QR code found" }, error.response_body)
    end
  end

  test "server errors and timeouts raise retryable errors" do
    snapshot = create_pending_snapshot("snap0001")

    with_stubs do |stubs|
      stubs.post("/decode_qr") { json({ detail: "boom" }, status: 500) }
      stubs.post("/decode_qr") { raise Faraday::TimeoutError }

      assert_raises(Faraday::ServerError) { FpTasks.decode_qr(snapshot) }
      assert_raises(Faraday::TimeoutError) { FpTasks.decode_qr(snapshot) }
    end
  end
end
