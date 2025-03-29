import Config

# config/runtime.exs is executed for all environments, including
# during releases. It is executed after compilation and before the
# system starts, so it is typically used to load production configuration
# and secrets from environment variables or elsewhere. Do not define
# any compile-time configuration in here, as it won't be applied.
# The block below contains prod specific runtime configuration.

# ## Using releases
#
# If you use `mix release`, you need to explicitly enable the server
# by passing the PHX_SERVER=true when you start it:
#
#     PHX_SERVER=true bin/livesecret start
#
# Alternatively, you can use `mix phx.gen.release` to generate a `bin/server`
# script that automatically sets the env var above.
if System.get_env("PHX_SERVER") do
  config :livesecret, LiveSecretWeb.Endpoint, server: true
end

if config_env() == :prod do
  config :ex_fdbmonitor,
    fdbmonitor: System.get_env("FDBMONITOR_PATH") || "/usr/local/libexec/fdbmonitor",
    fdbcli: System.get_env("FDBCLI_PATH") || "/usr/local/bin/fdbcli",
    fdbserver: System.get_env("FDBSERVER_PATH") || "/usr/local/libexec/fdbserver",
    fdbdr: System.get_env("FDBDR_PATH") || "/usr/local/bin/fdbdr",
    backup_agent:
      System.get_env("BACKUP_AGENT_PATH") || "/usr/local/foundationdb/backup_agent/backup_agent",
    dr_agent: System.get_env("DR_AGENT_PATH") || "/usr/local/bin/dr_agent"

  database_path =
    System.get_env("DATABASE_PATH") ||
      raise """
      environment variable DATABASE_PATH is missing.
      For example: /var/lib/livesecret/data
      """

  config :ex_fdbmonitor,
    etc_dir: Path.join(database_path, "etc"),
    run_dir: Path.join(database_path, "run")

  node_idx = String.to_integer(System.get_env("LIVESECRET_NODE_IDX") || "0")
  node_count = String.to_integer(System.get_env("LIVESECRET_NODE_COUNT") || "1")
  interface = System.get_env("LIVESECRET_COORDINATOR_IF") || "lo"

  addr_fn = fn if ->
    {:ok, addrs} = :inet.getifaddrs()

    addrs
    |> then(&:proplists.get_value(~c"#{if}", &1))
    |> then(&:proplists.get_all_values(:addr, &1))
    |> Enum.filter(&(tuple_size(&1) == 4))
    |> hd()
    |> :inet.ntoa()
    |> to_string()
  end

  config :ex_fdbmonitor,
    bootstrap: [
      cluster:
        if(node_idx > 0,
          do: :autojoin,
          else: [
            coordinator_addr: addr_fn.(interface)
          ]
        ),
      conf: [
        data_dir: Path.join(database_path, "data"),
        log_dir: Path.join(database_path, "log"),
        memory: System.get_env("FDBSERVER_MEMORY") || nil,
        cache_memory: System.get_env("FDBSERVER_CACHE_MEMORY") || nil,
        fdbservers: [[port: 4500]]
      ],
      fdbcli:
        if(node_idx == 0,
          do: ~w[configure new single #{System.get_env("FDB_STORAGE_ENGINE") || "ssd-redwood-1"}]
        ),
      fdbcli: if(node_idx == 2, do: ~w[configure double]),
      fdbcli: if(node_idx == node_count - 1, do: ~w[coordinators auto])
    ]

  # The secret key base is used to sign/encrypt cookies and other secrets.
  # A default value is used in config/dev.exs and config/test.exs but you
  # want to use a different value for prod and you most likely don't want
  # to check this value into version control, so we use an environment
  # variable instead.
  secret_key_base =
    System.get_env("SECRET_KEY_BASE") ||
      raise """
      environment variable SECRET_KEY_BASE is missing.
      You can generate one by calling: mix phx.gen.secret
      """

  host = System.get_env("PHX_HOST") || "example.com"
  port = String.to_integer(System.get_env("PORT") || "4000")

  config :livesecret, LiveSecretWeb.Endpoint,
    url: [host: host, port: 443, scheme: "https"],
    http: [
      # Enable IPv6 and bind on all interfaces.
      # Set it to  {0, 0, 0, 0, 0, 0, 0, 1} for local network only access.
      # See the documentation on https://hexdocs.pm/plug_cowboy/Plug.Cowboy.html
      # for details about using IPv6 vs IPv4 and loopback vs public addresses.
      ip: {0, 0, 0, 0, 0, 0, 0, 0},
      port: port
    ],
    secret_key_base: secret_key_base

  config :livesecret, LiveSecret.Expiration, interval: :timer.seconds(20)

  to_list = fn
    nil -> []
    "" -> []
    s -> String.split(s, ",")
  end

  config :livesecret, LiveSecretWeb.Presence,
    tenants: to_list.(System.get_env("TENANTS") || host),
    behind_proxy:
      "true" ==
        (System.get_env("BEHIND_PROXY") ||
           raise("""
           environment variable BEHIND_PROXY is missing.

           Use "true" if there is at least 1 reverse proxy between your client
           and the LiveSecret Phoenix server. It is strongly recommended to
           use a reverse proxy. If "true", also be sure to set REMOTE_IP_HEADER
           to define a trusted x-header to avoid spoofing.
           """)),

    # Define REMOTE_IP_HEADER as a the name of a trusted header on incoming HTTP
    # requests that defines the remote address for the end user. Typically this is
    # something like x-forwarded-for or x-real-ip. You must make sure you trust
    # whatever upstream proxy is setting this header.
    #    See remote_ip for more details
    remote_ip_header: System.get_env("REMOTE_IP_HEADER") || "x-forwarded-for",

    # Define REMOTE_IP_PROXIES as a comma-delimited list of CIDRs that represent
    # any proxies in between the end user and LiveSecret. When computing the remote
    # address for a user, these networks will be ignored.
    #    See remote_ip for more details
    remote_ip_proxies: to_list.(System.get_env("REMOTE_IP_PROXIES")),

    # Define REMOTE_IP_CLIENTS as a comma-delimited list of CIDRs that represent
    # any known client networks. For example -- By default, LiveSecret will ignore
    # a 10.0.0.0/8 address if it's computed as the remote address for a client. If
    # an address on this network is allowable, it must be defined in REMOTE_IP_CLIENTS.
    #    See remote_ip for more details
    remote_ip_clients: to_list.(System.get_env("REMOTE_IP_CLIENTS"))
end
