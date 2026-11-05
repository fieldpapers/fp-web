require 'test_helper'

class RateLimitTest < ActionDispatch::IntegrationTest
  include ActiveJob::TestHelper

  setup do
    host! "example.com"
  end

  def login(login, password, ip: "203.0.113.1")
    post user_session_path, params: { user: { login: login, password: password } }, env: { "REMOTE_ADDR" => ip }
  end

  def assert_rate_limited(path)
    assert_redirected_to path
    assert_equal "Too many attempts. Please wait a few minutes and try again.", flash[:alert]
  end

  test "logins to one account are limited, even from many IPs" do
    create_user("victim")
    10.times { |i| login("victim", "wrong", ip: "203.0.113.#{i}") }

    login("Victim", "password123", ip: "198.51.100.1")

    assert_rate_limited new_user_session_path
    get account_path
    assert_redirected_to new_user_session_path
  end

  test "logins from one IP are limited, even to many accounts" do
    20.times { |i| login("user#{i}", "wrong") }
    create_user("mapper")

    login("mapper", "password123")
    assert_rate_limited new_user_session_path

    login("mapper", "password123", ip: "198.51.100.1")
    assert_redirected_to root_path
  end

  test "password reset emails to one address are limited" do
    create_user("victim")

    4.times { |i| post user_password_path, params: { user: { email: "victim@example.com" } }, env: { "REMOTE_ADDR" => "203.0.113.#{i}" } }

    assert_rate_limited new_user_password_path
    assert_equal 3, ActionMailer::Base.deliveries.size
  end

  test "merging is limited per account" do
    user = create_osm_user("Mapper", 42)
    create_user("legacy")
    sign_in_as(user)

    10.times { |i| post merge_account_path, params: { login: "other#{i}", password: "wrong" } }
    post merge_account_path, params: { login: "legacy", password: "password123" }

    assert_rate_limited account_path
    assert User.exists?(username: "legacy", osm_id: nil)
  end

  test "atlas creation is limited per IP" do
    30.times { post compose_path, params: { atlas: { rows: 0 } } }
    refute_equal "Too many attempts. Please wait a few minutes and try again.", flash[:alert]

    post compose_path, params: { atlas: { rows: 0 } }

    assert_rate_limited compose_path
  end

  test "snapshot uploads are limited per IP" do
    stub = ->(*) { raise "rate limit should apply before create" }
    60.times { Rails.cache.increment("rate-limit:snapshots:127.0.0.1", 1, expires_in: 10.minutes) }

    Snapshot.stub(:create!, stub) do
      post snapshots_path, params: { snapshot: { s3_scene_url: "x" } }
    end

    assert_response :too_many_requests
  end

  private

  def sign_in_as(user)
    OmniAuth.config.test_mode = true
    OmniAuth.config.mock_auth[:osm] = OmniAuth::AuthHash.new(provider: "osm", uid: user.osm_id.to_s, info: { nickname: user.username })
    get "/users/auth/osm/callback"
  ensure
    OmniAuth.config.test_mode = false
    OmniAuth.config.mock_auth.delete(:osm)
  end
end
