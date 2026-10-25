# Client for fp-tasks (TASK_BASE_URL), which renders atlas PDFs and
# georeferences snapshots. Each call blocks until the work is done and returns
# the URL of the result.
#
# Raises Faraday::ClientError (usually a 422) when fp-tasks can't process the
# input, so retrying won't help, and other Faraday::Errors (5xx, timeouts,
# connection failures) when it might.
module FpTasks
  # read timeouts (seconds), above fp-tasks' subprocess timeouts of 60s and
  # 120s (for merges and georeferencing)
  TIMEOUT = 90
  LONG_TIMEOUT = 150

  extend self

  def render_page(page)
    post("render_page", page_payload(page), TIMEOUT)["pdf_url"]
  end

  def render_index(page)
    atlas = page.atlas
    payload = page_payload(page).merge(atlas_bbox: atlas.bbox, cols: atlas.cols, rows: atlas.rows)
    post("render_index", payload, TIMEOUT)["pdf_url"]
  end

  def merge_pages(atlas, pdf_urls)
    post("merge_pages", { slug: atlas.slug, pdf_urls: pdf_urls }, LONG_TIMEOUT)["pdf_url"]
  end

  # The URL in the QR code on a snapshot's image
  def decode_qr(snapshot)
    post("decode_qr", { image_url: snapshot.image_url }, TIMEOUT)["href"]
  end

  # Georeferences a snapshot's image as a picture of page
  def georeference(snapshot, page)
    atlas = page.atlas
    payload = {
      slug: snapshot.slug,
      image_url: snapshot.image_url,
      bbox: page.bbox,
      paper_size: atlas.paper_size,
      orientation: atlas.orientation,
      layout: atlas.layout,
    }
    post("georeference", payload, LONG_TIMEOUT)["geotiff_url"]
  end

  private

  def page_payload(page)
    atlas = page.atlas
    {
      slug: atlas.slug,
      page_number: page.page_number,
      bbox: page.bbox,
      zoom: page.zoom,
      provider: page.provider,
      paper_size: atlas.paper_size,
      orientation: atlas.orientation,
      layout: atlas.layout,
      text: atlas.text.to_s,
      title: atlas.title,
    }
  end

  def post(path, payload, timeout)
    connection.post(path, payload) { |req| req.options.timeout = timeout }.body
  end

  def connection
    @connection ||= Faraday.new(FieldPapers::TASK_BASE_URL, request: { open_timeout: 5 }) do |f|
      f.request :json
      f.response :raise_error
      f.response :json
    end
  end
end
