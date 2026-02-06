import Config

config :livesecret, LiveSecret.Repo, open_db: &EctoFoundationDB.Sandbox.open_db/1

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :livesecret, LiveSecretWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "RDekpi/uUZ0ZuKQ84ARGndoiHw9OBfrLb+yz6JycX2kN3yeZWc9NkI7f055Pepuo",
  server: false

config :livesecret, LiveSecret.Expiration, interval: :timer.seconds(20)

config :livesecret, LiveSecretWeb.Presence, tenants: ["localhost"], behind_proxy: false

# Print only warnings and errors during test
config :logger, level: :warning

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime

# Configure bun for JS tests
config :bun,
  version: "1.2.4",
  js_tests: [
    args: ~w(test --preload ./test/js/setup.js test/js),
    cd: Path.expand("../", __DIR__)
  ]
