module ApplicationHelper
  LOCALE_NAMES = {
    ar: "اَلْعَرَبِيَّةُ",
    cs: "Čeština",
    da: "Dansk",
    de: "Deutsch",
    en: "English",
    es: "Español",
    fr: "Français",
    hu: "Magyar nyelv",
    id: "Bahasa Indonesia",
    it: "Italiano",
    ja: "日本語",
    ku: "کوردی",
    nl: "Nederlands",
    pl: "Polski",
    pt: "Português",
    ru: "ру́сский",
    sw: "Kiswahili",
    tl: "Tagalog",
    uk: "Українська",
    vi: "tiếng Việt",
    zh_CN: "普通话",
    zh_TW: "國語",
  }

  # Inlines an SVG from app/assets/images/icons, so that it takes on the
  # surrounding text color and font size.
  def icon(name, extra_class = nil)
    svg = Rails.root.join("app/assets/images/icons/#{name}.svg").read[/<svg.*/m]
    svg.sub("<svg", %(<svg class="#{["icon", extra_class].compact.join(" ")}" aria-hidden="true")).html_safe
  end

  def locale_options
    options = LOCALE_NAMES.map { |code, name| [name, code, { lang: code.to_s.tr("_", "-") }] }
    options_for_select(options, I18n.locale)
  end

  # Used to set the active navbar item
  def current_nav_target
    target = ""
    if controller_name == "compose"
      target = "compose"
    elsif controller_name == 'snapshots' && action_name == 'new'
      target = 'upload'
    elsif ["snapshots", "atlases"].include? controller_name
      target = 'watch'
    elsif controller_name == 'home' && action_name == 'advanced'
      target = 'extend'
    elsif ["sessions","registrations","confirmations"].include? controller_name
      target = 'sessions'
    end
    return target
  end

  def id_link(zoom, lon, lat, slug = nil)
    if slug
      "#{FieldPapers::OSM_BASE_URL}/edit#background=custom:#{FieldPapers::TILE_BASE_URL}/snapshots/#{slug}/{z}/{x}/{y}.png&map=#{zoom}/#{lat}/#{lon}"
    else
      "#{FieldPapers::OSM_BASE_URL}/edit#map=#{zoom}/#{lat}/#{lon}"
    end
  end

  def potlatch_link(zoom, lon, lat, slug = nil)
    if slug
      "#{FieldPapers::OSM_BASE_URL}/edit?lat=#{lat}&lon=#{lon}&zoom=#{zoom}&tileurl=#{FieldPapers::TILE_BASE_URL}/snapshots/#{slug}/$z/$x/$y.png"
    else
      "#{FieldPapers::OSM_BASE_URL}/edit?lat=#{lat}&lon=#{lon}&zoom=#{zoom}"
    end
  end

  # derives URLs for HTTP GET requests needed for JOSM to load data and tiles.
  # Actual XHRs exist in <script> in show.html.erb.
  def josm_link(zoom, lon, lat, north, south, east, west, provider, slug = nil)
    protocol = URI.parse(request.original_url).scheme
    port = protocol == "https" ? "8112" : "8111"
    domain = "127.0.0.1"

    provider = provider.gsub("{S}", "{switch:a,b,c}").gsub("{Z}", "{zoom}").gsub("{Y}", "{y}").gsub("{X}", "{x}");

    # load data and zoom to extents
    dataRequest = "#{protocol}://#{domain}:#{port}/load_and_zoom?left=#{west}&right=#{east}&top=#{north}5&bottom=#{south}"

    # load tiles
    if slug
      tileRequest = "#{protocol}://#{domain}:#{port}/imagery?title=osm&type=tms&url=#{FieldPapers::TILE_BASE_URL}/snapshots/#{slug}/{zoom}/{x}/{y}.png"
    else
      tileRequest = "#{protocol}://#{domain}:#{port}/imagery?title=osm&type=tms&url=#{provider}"
    end

    return "data-data-request=#{dataRequest} data-tile-request=#{tileRequest}"
  end
end
