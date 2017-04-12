defmodule Hexpm.Web.PasswordResetController do
  use Hexpm.Web, :controller

  def show(conn, _params) do
    render conn, "show.html", [
      title: "Reset your password",
      container: "container page password-view"
    ]
  end

  def create(conn, %{"username" => name}) do
    Users.password_reset_init(name, audit: audit_data(conn))

    render conn, "create.html", [
      title: "Reset your password",
      container: "container page password-view",
      communication: communication_method()
    ]
  end

  defp communication_method do
    if Application.get_env(:hexpm, :slack) do
      "a slack message"
    else
      "an email"
    end
  end
end
