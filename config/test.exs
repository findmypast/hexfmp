use Mix.Config

config :hexpm,
  user_agent_req: false,

  docs_url:    System.get_env("HEX_DOCS_URL") || "http://localhost:4042",
  cdn_url:     System.get_env("HEX_CDN_URL")  || "http://localhost:4042",
  secret:      System.get_env("HEX_SECRET")   || "796f75666f756e64746865686578",
  private_key: File.read!("test/fixtures/private.pem"),
  public_key:  File.read!("test/fixtures/public.pem")

config :hexpm, Hexpm.Web.Endpoint,
  http: [port: 4000],
  server: false

config :hexpm, Hexpm.Emails.Mailer,
  adapter: Bamboo.LocalAdapter

config :hexpm, Hexpm.Repo,
  adapter: Ecto.Adapters.Postgres,
  username: "postgres",
  password: "postgres",
  database: "hexpm_test",
  hostname: "postgres",
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: 10,
  ownership_timeout: 61_000

config :logger,
  level: :error
