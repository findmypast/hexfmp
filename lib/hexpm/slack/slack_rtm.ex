defmodule Hexpm.Slack.SlackRtm do
  use Slack

  alias Hexpm.Vault.Raider

  defp save_to_env(slack_rtm_pid) do
    Application.put_env(:hexpm, :slack_rtm, slack_rtm_pid)
    {:ok, slack_rtm_pid}
  end

  if Mix.env == :prod do
    def start(opts \\ []) do
      with {:ok, token} <- Raider.raid_vault(System.get_env("SLACK_TOKEN_VAULT_KEY")),
           {:ok, slack_rtm_pid} <- Slack.Bot.start_link(__MODULE__, [], token),
        do: save_to_env(slack_rtm_pid)
    end
  else
   def start(opts \\ []), do: {:ok, self()}
    # def start(opts \\ []) do
    #   with {:ok, slack_rtm_pid} <- Slack.Bot.start_link(__MODULE__, [], System.get_env("SLACK_TOKEN")),
    #     do: save_to_env(slack_rtm_pid)
    # end
  end

  def handle_connect(slack, state) do
    IO.puts "Connected as #{slack.me.name}"
    {:ok, state}
  end

  def handle_event(message = %{type: "message"}, slack, state) do
    #send_message("fecking vegans", message.channel, slack)
    {:ok, state}
  end
  def handle_event(_, _, state), do: {:ok, state}

  def handle_info({:message, text, channel}, slack, state) do
    send_message(text, channel, slack)
    {:ok, state}
  end
  def handle_info(_, _, state), do: {:ok, state}
end
