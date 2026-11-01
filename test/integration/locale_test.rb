require 'test_helper'

class LocaleTest < ActionDispatch::IntegrationTest
  setup do
    host! "example.com"
  end

  test "locale picker sets cookie and redirects back" do
    post change_locale_path, params: { locale: "es" }, headers: { "Referer" => "http://example.com/about" }

    assert_redirected_to "/about"
    assert_equal "es", cookies[:locale]

    get about_path
    assert_select "#locale-menu button[aria-current][value=es]"
  end

  test "locale picker ignores offsite referer" do
    post change_locale_path, params: { locale: "es" }, headers: { "Referer" => "https://evil.example/" }

    assert_redirected_to root_path
  end

  test "locale query param sets cookie and redirects to canonical url" do
    get "/atlases?locale=fr&month=2026-01"

    assert_redirected_to "/atlases?month=2026-01"
    assert_equal "fr", cookies[:locale]

    get root_path("locale" => "de")
    assert_redirected_to "/"
  end

  test "accept-language is used without a cookie" do
    get about_path, headers: { "Accept-Language" => "ja" }

    assert_response :success
    assert_select "#locale-menu button[aria-current][value=ja]"
  end

  test "default locale is used when nothing matches" do
    get about_path, headers: { "Accept-Language" => "ja" }
    get about_path, headers: { "Accept-Language" => "xx" }

    assert_select "#locale-menu button[aria-current][value=en]"
  end
end
