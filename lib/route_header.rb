# Rack middleware that reports the matched route pattern (e.g. "/atlases/:id")
# in an X-Route response header, so that the reverse proxy's access logs can be
# aggregated by route without knowing this app's URL scheme.
#
# It sits at the top of the middleware stack (outside ShowExceptions), so error
# responses are labeled too. Requests that never reach the router (static files,
# Rack::Rewrite redirects, unmatched paths, etc) get no header.
class RouteHeader
  def initialize(app)
    @app = app
  end

  def call(env)
    status, headers, body = @app.call(env)
    route = ActionDispatch::Request.new(env).route_uri_pattern
    headers["X-Route"] = route.delete_suffix("(.:format)") if route
    [status, headers, body]
  end
end
