defmodule Hexpm.Repo do
  use Ecto.Repo,
    otp_app: :hexpm,
    adapter: Ecto.Adapters.Postgres

  alias Hexpm.Vault.Raider

  defp database_parameters do
    [{:username, System.get_env("DB_USERNAME_VAULT_KEY")},
     {:password, System.get_env("DB_PASSWORD_VAULT_KEY")},
     {:hostname, System.get_env("DB_HOSTNAME_VAULT_KEY")},
     {:database, System.get_env("DB_DATABASE_VAULT_KEY")}]
  end

  def init(opts \\ []) do
    database_parameters()
    |> Enum.scan(opts, &raid_vault_and_add_to_opts/2)
    |> start_link
  end

  defp raid_vault_and_add_to_opts({key, vault_location}, _opts) do
    case Raider.raid_vault(vault_location) do
      {:ok, value} -> {key, value}
      {:error, key, _tuple} -> raise "Cannot raid vault for #{key}"
    end
  end
  
  @advisory_locks %{
    registry: 1
  }

  def refresh_view(schema) do
    source = schema.__schema__(:source)

    {:ok, _} = Ecto.Adapters.SQL.query(
       Hexpm.Repo,
       ~s(REFRESH MATERIALIZED VIEW "#{source}"),
       [])
    :ok
  end

  def transaction_with_isolation(fun_or_multi, opts) do
    false = Hexpm.Repo.in_transaction?
    level = Keyword.fetch!(opts, :level)

    transaction(fn ->
      {:ok, _} = Ecto.Adapters.SQL.query(Hexpm.Repo, "SET TRANSACTION ISOLATION LEVEL #{level}", [])
      transaction(fun_or_multi, opts)
    end, opts)
    |> unwrap_transaction_result
  end

  defp unwrap_transaction_result({:ok, result}), do: result
  defp unwrap_transaction_result(other), do: other

  def advisory_lock(key, opts) do
    {:ok, _} = Ecto.Adapters.SQL.query(
       Hexpm.Repo,
       "SELECT pg_advisory_xact_lock($1)",
       [Map.fetch!(@advisory_locks, key)],
       opts)
    :ok
  end
end
