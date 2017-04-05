use Mix.Config

config :hexpm,
  cookie_sign_salt: System.get_env("HEX_COOKIE_SIGNING_SALT"),
  cookie_encr_salt: System.get_env("HEX_COOKIE_ENCRYPTION_SALT")

config :hexpm, Hexpm.Web.Endpoint,
  http: [port: {:system, "PORT"}],
  url: [host: System.get_env("HEX_URL"), scheme: "https", port: 443],
  force_ssl: [hsts: true, host: nil, rewrite_on: [:x_forwarded_proto]],
  cache_static_manifest: "priv/static/cache_manifest.json",
  secret_key_base: System.get_env("HEX_SECRET_KEY_BASE")

config :hexpm, Hexpm.Repo,
  adapter: Ecto.Adapters.Postgres,
  pool_size: System.get_env("NUM_DATABASE_CONNS") || 20,
  ssl: true

config :comeonin,
  bcrypt_log_rounds: 12

config :rollbax,
  access_token: System.get_env("ROLLBAR_ACCESS_TOKEN"),
  environment: to_string(Mix.env),
  enabled: !!System.get_env("ROLLBAR_ACCESS_TOKEN")

config :logger, level: :warn
config :logger,
  backends: [:console, {Logger.Backends.Gelf, :gelf_logger}]

config :logger, :gelf_logger,
  host: "graylog.dun.fh",
  port: 1516,
  level: :warn,
  application: "Arq",
  compression: :gzip, # Defaults to :gzip, also accepts :zlib or :raw
  metadata: [:request_id, :module, :file, :facility]
