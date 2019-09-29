import Config

database_url =
  System.get_env("DATABASE_URL") ||
    raise """
    environment variable DATABASE_URL is missing.
    For example: ecto://USER:PASS@HOST/DATABASE
    """

database_pool_size = String.to_integer(System.get_env("POOL_SIZE") || "10")

config :live_view_demo, LiveViewDemo.Repo,
  # ssl: true,
  url: database_url,
  pool_size: database_pool_size

secret_key_base =
  System.get_env("SECRET_KEY_BASE") ||
    raise """
    environment variable SECRET_KEY_BASE is missing.
    You can generate one by calling: mix phx.gen.secret
    """

port = String.to_integer(System.get_env("PORT") || "4000")
site_scheme = System.get_env("SITE_SCHEME") || "https"
site_port = String.to_integer(System.get_env("SITE_PORT") || "443")
site_host = System.fetch_env!("SITE_HOST")

config :live_view_demo, LiveViewDemoWeb.Endpoint,
  url: [scheme: site_scheme, host: site_host, port: site_port],
  http: [:inet6, port: port],
  secret_key_base: secret_key_base,
  server: true
