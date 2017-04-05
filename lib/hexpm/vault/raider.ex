defmodule Hexpm.Vault.Raider do
  @moduledoc """
  Vault raider accesses the vault to retrieve details needed for making calls to
  more sensitive APIs
  """

  alias Vaultex.Client, as: Vault

  def raid_vault(vault_key) do
    vault_key_string = to_string(vault_key)
    get_value_from_vault("secret/hexfmp/" <> vault_key_string)
  end

  defp get_value_from_vault(key) do
    vault_username = ~s(#{get_service_name()}-#{get_service_tags()})
    vault_password = get_vault_pass()

    vault_response =
      Vault.read(key, :userpass, {vault_username, vault_password})

    case vault_response do
      {:ok, %{"value" => value}} -> {:ok, value}
      {:error, reasons} -> {:error, key, {:vaultex, reasons}}
    end
  end

  defp get_service_name, do: System.get_env("SERVICE_NAME")
  defp get_service_tags, do: System.get_env("SERVICE_TAGS")
  defp get_vault_pass, do: System.get_env("VAULT_PASS")
end
