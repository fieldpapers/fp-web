module AtlasesHelper

  # Used in CSV output
  def atlas_person_href(atlas)
    if atlas.user_id
      atlas_url(user: atlas.user_id)
    end
  end

end
