defmodule Hexpm.Web.EmailController do
  use Hexpm.Web, :controller

  # TODO: Sign in user after verification

  def verify(conn, %{"username" => username, "email" => email, "key" => key}) do
    success = Users.verify_email(username, email, key) == :ok

    conn =
      if success,
        do: put_flash(conn, :info, success_message(email)),
      else: put_flash(conn, :error, fail_message(email))

    conn
    |> put_flash(:custom_location, true)
    |> redirect(to: page_path(Hexpm.Web.Endpoint, :index))
  end

  defp success_message(email) do
    if Application.get_env(:hexpm, :slack) do
      "Your slack target #{email} has been verified."
    else
      "Your email #{email} has been verified."
    end
  end

  defp fail_message(email) do
    if Application.get_env(:hexpm, :slack) do
      "Your slack target #{email} failed to verify."
    else
      "Your email #{email} failed to verify."
    end
  end
end
