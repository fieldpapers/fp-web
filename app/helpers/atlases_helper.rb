module AtlasesHelper

  # Used in CSV & GeoJSON output
  def atlas_person_href(atlas)
    if atlas.user_id
      atlas_url(user: atlas.user_id)
    end
  end

  # TODO: rewrite this mess
  def atlas_to_geojson(atlas)
    out = {type: 'FeatureCollection', features: []}

    # create Atlas feature
    feature = {
      type: 'Feature',
      properties: {
          type: 'atlas',
          creator: atlas.creator_name,
          title: atlas.title,
          description: atlas.text,
          providers: atlas.provider,
          paper_size: atlas.paper_size,
          orientation: atlas.orientation,
          layout: atlas.layout,
          zoom: atlas.zoom,
          rows: atlas.rows,
          cols: atlas.cols,
          pages: atlas.atlas_pages,
          created: atlas.created_at.strftime('%a, %e %b %Y %H:%M:%S %z'),
          url: atlas_url(atlas),
          url_pdf: atlas.pdf_url,
          url_user: atlas_person_href(atlas),
      },
      geometry: {
          type: 'MultiPolygon',
          coordinates: nil
      }
    }

    polys = []
    atlas.pages.each do |p|
      polys.push([[
        [p.west, p.south],
        [p.west, p.north],
        [p.east, p.north],
        [p.east, p.south],
        [p.west, p.south]
      ]]);
    end

    feature[:geometry][:coordinates] = polys
    out[:features].push(feature)

    # create pages
    atlas.pages.each do |page|
      bbox = page.bbox

      out[:features].push({
        type: 'Feature',
        properties: {
            type: 'page',
            provider: page.provider,
            page_number: page.page_number,
            zoom: page.zoom,
            created: page.created_at.strftime('%a, %e %b %Y %H:%M:%S %z'),
            url: atlas_url(atlas) + "/" + page.page_number,
        },
        geometry: {
            type: 'Polygon',
            coordinates: [[
              [bbox[0],bbox[1]],
              [bbox[0],bbox[3]],
              [bbox[2],bbox[3]],
              [bbox[2],bbox[1]],
              [bbox[0],bbox[1]]
            ]]
        }
      })
    end


    # create snapshot features
    atlas.snapshots.each do |snapshot|
      bbox = snapshot.bbox

      out[:features].push({
        type: 'Feature',
        properties: {
            type: 'snapshot',
            title: snapshot.title,
            description: snapshot.description,
            uploader: snapshot.uploader_name,
            created: snapshot.created_at.strftime('%a, %e %b %Y %H:%M:%S %z'),
            min_row: snapshot.min_row,
            max_row: snapshot.max_row,
            min_column: snapshot.min_column,
            max_column: snapshot.max_column,
            min_zoom: snapshot.min_zoom,
            max_zoom: snapshot.max_zoom,
            base_url: snapshot.base_url,
            url: snapshot_url(snapshot),
            url_page: atlas_url(atlas) + "/" + snapshot.page.page_number,
            url_uploader: snapshot_person_href(snapshot),
        },
        geometry: {
            type: 'Polygon',
            coordinates: [[
              [bbox[0],bbox[1]],
              [bbox[0],bbox[3]],
              [bbox[2],bbox[3]],
              [bbox[2],bbox[1]],
              [bbox[0],bbox[1]]
            ]]
        }
      })
    end

    # notes features?

    return out
  end # end atlas_to_geojson

end
