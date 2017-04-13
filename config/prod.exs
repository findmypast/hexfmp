use Mix.Config

config :hexpm,
  cookie_sign_salt: "lYEJ7Wc8jFwNrPke", # System.get_env("HEX_COOKIE_SIGNING_SALT"),
  cookie_encr_salt: "TZDiyTeFQ819hsC3", # System.get_env("HEX_COOKIE_ENCRYPTION_SALT")
  secret: "796f75666f756e64746865686578", # System.get_env("HEX_SECRET")
  private_key: File.read!("test/fixtures/private.pem") # System.get_env("HEX_SIGNING_KEY")

config :hexpm, Hexpm.Web.Endpoint,
  http: [port: 4000, ip: {0, 0, 0, 0}],
  url: [host: System.get_env("PRODUCTION_URL")],
  cache_static_manifest: "priv/static/cache_manifest.json",
  secret_key_base: "Cc2cUvbm9x/uPD01xnKmpmU93mgZuht5cTejKf/Z2x0MmfqE1ZgHJ1/hSZwd8u4L" # System.get_env("SECRET_KEY_BASE")

config :hexpm, Hexpm.Repo,
  adapter: Ecto.Adapters.Postgres,
  pool_size: System.get_env("NUM_DATABASE_CONNS") || 20,
  ssl: true

config :comeonin,
  bcrypt_log_rounds: 12

config :logger, level: :warn
config :logger,
  backends: [:console, {Logger.Backends.Gelf, :gelf_logger}]

config :logger, :gelf_logger,
  host: "graylog.dun.fh",
  port: 1516,
  level: :warn,
  application: "Hexfmp",
  compression: :gzip, # Defaults to :gzip, also accepts :zlib or :raw
  metadata: [:request_id, :module, :file, :facility]

config :ex_statsd,
       host: "graphite.dun.fh",
       namespace: "hexfmp"
