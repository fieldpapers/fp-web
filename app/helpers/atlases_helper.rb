module AtlasesHelper

  # Used in CSV output
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
          person_href: atlas_person_href(atlas),
          href: atlas_url(atlas),
          created: atlas.created_at.strftime('%a, %e %b %Y %H:%M:%S %z')
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


    # create snapshot features
    atlas.snapshots.each do |snapshot|
      bbox = snapshot.bbox

      out[:features].push({
        type: 'Feature',
        properties: {
            type: 'snapshot',
            person_href: snapshot_person_href(snapshot),
            href: snapshot_url(snapshot),
            atlas_page_href: atlas_url(atlas) + "/" + snapshot.page.page_number,
            created: snapshot.created_at.strftime('%a, %e %b %Y %H:%M:%S %z')
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
