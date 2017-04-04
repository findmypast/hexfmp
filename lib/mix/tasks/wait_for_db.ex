defmodule Mix.Tasks.WaitForDb do
  use Mix.Task
  use Retry

  require Logger

  def run(_) do
    host_name = Application.get_env(:hexpm, Hexpm.Repo)
      |> Keyword.get(:hostname)

    {:ok, {_, _, _, _, _, [ip_tuple]}} = :inet.gethostbyname(to_char_list host_name)

    retry with: Stream.cycle([500]) do
      Logger.info("Trying to find postgres on #{host_name} with IP #{inspect(ip_tuple)}")
      result = :gen_tcp.connect(ip_tuple, 5432, [])
      case result do
        {:ok, socket} -> :gen_tcp.close(socket)
        _ -> {:error}
      end
      result
    end
  end
end
