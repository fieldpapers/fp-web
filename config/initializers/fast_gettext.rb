require 'gettext_i18n_rails/string_interpolate_fix'

FastGettext.add_text_domain('app', path: 'locale', type: :po)
FastGettext.default_available_locales = %w(ar cs da de en es es_MX fr hu id it ja ku nl pl pt pt_BR ru sw tl uk vi zh_CN zh_TW)
FastGettext.default_text_domain = 'app'
FastGettext.default_locale = 'en'
