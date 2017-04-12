defmodule Hexpm.Web.SignupController do
  use Hexpm.Web, :controller

  def show(conn, _params) do
    render_show(conn, User.build(%{}))
  end

  def create(conn, params) do
    case Users.add(params["user"], audit: audit_data(conn)) do
      {:ok, _user} ->
        if Application.get_env(:hexpm, :slack) do
          conn
          |> put_flash(:info, "A confirmation message has been sent to you via slack, check your private messages.")
          |> put_flash(:custom_location, true)
          |> redirect(to: page_path(Hexpm.Web.Endpoint, :index))
        else
          conn
          |> put_flash(:info, "A confirmation email has been sent, you will have access to your account shortly.")
          |> put_flash(:custom_location, true)
          |> redirect(to: page_path(Hexpm.Web.Endpoint, :index))
        end
      {:error, changeset} ->
        conn
        |> put_status(400)
        |> render_show(changeset)
    end
  end

  defp render_show(conn, changeset) do
    if Application.get_env(:hexpm, :slack) do
      render conn, "show_slack.html", [
        title: "Sign up",
        container: "container page signup",
        changeset: changeset
      ]
    else
      render conn, "show.html", [
        title: "Sign up",
        container: "container page signup",
        changeset: changeset
      ]
    end
  end
end
