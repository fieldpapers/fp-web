require "i18n/backend/fallbacks"

# Don't complain if locales aren't available in support packages (e.g.
# rails_i18n, etc.)
I18n.config.enforce_available_locales = false

# configure fallbacks, so zh_CN falls back to zh
I18n::Backend::Simple.send(:include, I18n::Backend::Fallbacks)
