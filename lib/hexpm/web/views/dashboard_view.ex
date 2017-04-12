defmodule Hexpm.Web.DashboardView do
  use Hexpm.Web, :view

  defp pages do
    if Application.get_env(:hexpm, :slack) do
      [profile: "Profile",
      password: "Password",
      email: "Slack"]
    else
      [profile: "Profile",
      password: "Password",
      email: "Email"]
    end
  end

  defp selected(conn, id) do
    if List.last(conn.path_info) == Atom.to_string(id) do
      "selected"
    end
  end

  defp public_email_options(user) do
    emails = Email.order_emails(user.emails)

    if Application.get_env(:hexpm, :slack) do
      [{"Don't show a slack target", "none"}] ++
        Enum.filter_map(emails, & &1.verified, &{&1.email, &1.email})
    else
      [{"Don't show a public email address", "none"}] ++
        Enum.filter_map(emails, & &1.verified, &{&1.email, &1.email})
    end
  end

  defp public_email_value(user) do
    User.email(user, :public) || "none"
  end
end
