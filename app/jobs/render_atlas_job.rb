# Renders an atlas's pages, then merges them into the atlas PDF. Pages
# already rendered are skipped, so a retried job resumes where it stopped.
class RenderAtlasJob < FpTasksJob
  def perform(atlas_id)
    atlas = record
    return unless atlas.incomplete?

    pages = atlas.pages.to_a
    pages.each do |page|
      next if page.composed_at

      pdf_url = page.page_number == "i" ? FpTasks.render_index(page) : FpTasks.render_page(page)
      page.update!(pdf_url: pdf_url, composed_at: Time.current)
      # the last step is the merge
      atlas.update_column(:progress, pages.count(&:composed_at).fdiv(pages.size + 1))
    end

    pdf_url = FpTasks.merge_pages(atlas, pages.map(&:pdf_url))
    notify(atlas) if atlas.mark_complete!(pdf_url: pdf_url, progress: 1)
  end

  def record
    @record ||= Atlas.unscoped.find(arguments.first)
  end

  private

  # POSTs the atlas's GeoJSON to each of ATLAS_COMPLETE_WEBHOOKS
  def notify(atlas)
    urls = FieldPapers::ATLAS_COMPLETE_WEBHOOKS.split(/\s*,\s*/)
    return if urls.empty?

    body = { atlas: atlas.as_json(geojson: true) }
    client = Faraday.new(request: { open_timeout: 5, timeout: 30 }) { |f| f.request :json }

    urls.each do |url|
      rsp = client.post(url, body)
      logger.error("Webhook #{url} returned #{rsp.status}: #{rsp.body}") unless rsp.success?
    rescue Faraday::Error => e
      logger.error("Webhook #{url} failed: #{e.message}")
    end
  end
end
