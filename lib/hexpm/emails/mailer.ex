defmodule Hexpm.Emails.Mailer do
  use Bamboo.Mailer, otp_app: :hexpm

  def deliver_now_throttled(email) do
    if Application.get_env(:hexpm, :slack) do
      :ok
    else
      ses_rate = Application.get_env(:hexpm, :ses_rate) |> String.to_integer

      email
      |> recipients
      |> recipient_chunks(ses_rate)
      |> Enum.each(fn chunk ->
        Hexpm.Throttle.wait(Hexpm.SESThrottle, length(chunk))
        email
        |> Bamboo.Email.to(chunk)
        |> Hexpm.Emails.Mailer.deliver_now
      end)
    end
  end

  defp recipient_chunks(recipients, limit),
    do: Enum.chunk(recipients, limit, limit, [])

  defp recipients(email) do
    email
    |> Bamboo.Mailer.normalize_addresses
    |> Bamboo.Email.all_recipients
  end
end
