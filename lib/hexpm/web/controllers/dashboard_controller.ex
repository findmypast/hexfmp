defmodule Hexpm.Web.DashboardController do
  use Hexpm.Web, :controller

  plug :requires_login

  def index(conn, _params) do
    redirect(conn, to: dashboard_path(conn, :profile))
  end

  def profile(conn, _params) do
    user = conn.assigns.logged_in
    render_profile(conn, User.update_profile(user, %{}))
  end

  def update_profile(conn, params) do
    user = conn.assigns.logged_in

    case Users.update_profile(user, params["user"], audit: audit_data(conn)) do
      {:ok, _user} ->
        conn
        |> put_flash(:info, "Profile updated successfully.")
        |> redirect(to: dashboard_path(conn, :profile))
      {:error, changeset} ->
        conn
        |> put_status(400)
        |> render_profile(changeset)
    end
  end

  def password(conn, _params) do
    user = conn.assigns.logged_in
    render_password(conn, User.update_password(user, %{}))
  end

  def update_password(conn, params) do
    user = conn.assigns.logged_in

    case Users.update_password(user, params["user"], audit: audit_data(conn)) do
      {:ok, _user} ->
        # TODO: Maybe send an email here?
        conn
        |> put_flash(:info, "Your password has been updated.")
        |> redirect(to: dashboard_path(conn, :password))
      {:error, changeset} ->
        conn
        |> put_status(400)
        |> render_password(changeset)
    end
  end

  def email(conn, _params) do
    user = Users.with_emails(conn.assigns.logged_in)
    render_email(conn, user)
  end

  def add_email(conn, params) do
    user = Users.with_emails(conn.assigns.logged_in)

    case Users.add_email(user, params["email"], audit: audit_data(conn)) do
      {:ok, _user} ->
        email = params["email"]["email"]
        if Application.get_env(:hexpm, :slack) do
          conn
          |> put_flash(:info, "A verification slack message has been sent to #{email}.")
          |> redirect(to: dashboard_path(conn, :email))
        else
          conn
          |> put_flash(:info, "A verification email has been sent to #{email}.")
          |> redirect(to: dashboard_path(conn, :email))
        end
      {:error, changeset} ->
        conn
        |> put_status(400)
        |> render_email(user, changeset)
    end
  end

  def remove_email(conn, params) do
    user = Users.with_emails(conn.assigns.logged_in)
    email = params["email"]

    case Users.remove_email(user, params, audit: audit_data(conn)) do
      :ok ->
        if Application.get_env(:hexpm, :slack) do
          conn
          |> put_flash(:info, "Removed slack target #{email} from your account.")
          |> redirect(to: dashboard_path(conn, :email))
        else
          conn
          |> put_flash(:info, "Removed email #{email} from your account.")
          |> redirect(to: dashboard_path(conn, :email))
        end
      {:error, reason} ->
        conn
        |> put_flash(:error, email_error_message(reason, email))
        |> redirect(to: dashboard_path(conn, :email))
    end
  end

  def primary_email(conn, params) do
    user = Users.with_emails(conn.assigns.logged_in)
    email = params["email"]

    case Users.primary_email(user, params, audit: audit_data(conn)) do
      :ok ->
        if Application.get_env(:hexpm, :slack) do
          conn
          |> put_flash(:info, "Your primary slack target was changed to #{email}.")
          |> redirect(to: dashboard_path(conn, :email))
        else
          conn
          |> put_flash(:info, "Your primary email was changed to #{email}.")
          |> redirect(to: dashboard_path(conn, :email))
        end
      {:error, reason} ->
        conn
        |> put_flash(:error, email_error_message(reason, email))
        |> redirect(to: dashboard_path(conn, :email))
    end
  end

  def public_email(conn, params) do
    user = Users.with_emails(conn.assigns.logged_in)
    email = params["email"]

    case Users.public_email(user, params, audit: audit_data(conn)) do
      :ok ->
        if Application.get_env(:hexpm, :slack) do
          conn
          |> put_flash(:info, "Your public slack target was changed to #{email}.")
          |> redirect(to: dashboard_path(conn, :email))
        else
          conn
          |> put_flash(:info, "Your public email was changed to #{email}.")
          |> redirect(to: dashboard_path(conn, :email))
        end
      {:error, reason} ->
        conn
        |> put_flash(:error, email_error_message(reason, email))
        |> redirect(to: dashboard_path(conn, :email))
    end
  end

  def resend_verify_email(conn, params) do
    user = Users.with_emails(conn.assigns.logged_in)
    email = params["email"]

    case Users.resend_verify_email(user, params) do
      :ok ->
        if Application.get_env(:hexpm, :slack) do
          conn
          |> put_flash(:info, "A verification slack message has been sent to #{email}.")
          |> redirect(to: dashboard_path(conn, :email))
        else
          conn
          |> put_flash(:info, "A verification email has been sent to #{email}.")
          |> redirect(to: dashboard_path(conn, :email))
        end
      {:error, reason} ->
        conn
        |> put_flash(:error, email_error_message(reason, email))
        |> redirect(to: dashboard_path(conn, :email))
    end
  end

  defp render_profile(conn, changeset) do
    if Application.get_env(:hexpm, :slack) do
      render conn, "profile_slack.html", [
        title: "Dashboard - Public profile",
        container: "container page dashboard",
        changeset: changeset
      ]
    else
      render conn, "profile.html", [
        title: "Dashboard - Public profile",
        container: "container page dashboard",
        changeset: changeset
      ]
    end
  end

  defp render_password(conn, changeset) do
    render conn, "password.html", [
      title: "Dashboard - Change password",
      container: "container page dashboard",
      changeset: changeset
    ]
  end

  defp render_email(conn, user, add_email_changeset \\ add_email_changeset()) do
    emails = Email.order_emails(user.emails)

    if Application.get_env(:hexpm, :slack) do
      render conn, "email_slack.html", [
        title: "Dashboard - Slack",
        container: "container page dashboard",
        add_email_changeset: add_email_changeset,
        emails: emails
      ]
    else
      render conn, "email.html", [
        title: "Dashboard - Email",
        container: "container page dashboard",
        add_email_changeset: add_email_changeset,
        emails: emails
      ]
    end
  end

  defp add_email_changeset do
    Email.changeset(%Email{}, :create, %{}, false)
  end

  if Application.get_env(:hexpm, :slack) do
    defp email_error_message(:unknown_email, email), do: "Unknown slack target #{email}."
    defp email_error_message(:not_verified, email), do: "Slack target #{email} not verified."
    defp email_error_message(:already_verified, email), do: "Slack target #{email} already verified."
    defp email_error_message(:primary, email), do: "Cannot remove primary slack target #{email}."
  else
    defp email_error_message(:unknown_email, email), do: "Unknown email #{email}."
    defp email_error_message(:not_verified, email), do: "Email #{email} not verified."
    defp email_error_message(:already_verified, email), do: "Email #{email} already verified."
    defp email_error_message(:primary, email), do: "Cannot remove primary email #{email}."
  end
end
