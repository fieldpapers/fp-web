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
    assert_select "select#locale option[selected][value=es]"
  end

  test "locale picker ignores offsite referer" do
    post change_locale_path, params: { locale: "es" }, headers: { "Referer" => "https://evil.example/" }

    assert_redirected_to root_path
  end

  test "locale query param sets cookie and redirects to canonical url" do
    get "/atlases?locale=fr&username=mapper"

    assert_redirected_to "/atlases?username=mapper"
    assert_equal "fr", cookies[:locale]

    get root_path("locale" => "de")
    assert_redirected_to "/"
  end

  test "accept-language is used without a cookie" do
    get about_path, headers: { "Accept-Language" => "ja" }

    assert_response :success
    assert_select "select#locale option[selected][value=ja]"
  end
end
