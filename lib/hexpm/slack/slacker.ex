defmodule Hexpm.Slack.Slacker do
  alias Hexpm.Accounts.User
  use Hexpm.Web, :view

  def send_to(message, target) do
    send slack_rtm(), {:message, message, target}
  end

  def verification(user, email) do
    email_path(Hexpm.Web.Endpoint, :verify, username: user.username, email: email.email, key: email.verification_key)
    |> verification_message
    |> send_to(email.email)
  end

  defp verification_message(verify_url) do
    """
    Are you really you? Are you sure? #{verify_url} ?
    """
  end

  def password_reset_request(user) do
    password_path(Hexpm.Web.Endpoint, :show, username: user.username, key: user.reset_key)
    |> password_reset_message
    |> send_to(User.email(user, :primary))
  end

  defp password_reset_message(reset_url) do
    """
    We heard you've lost your password, great job.
    Not to worry though, admit you're a simpleton by going here: #{reset_url}
    Thank goodness for automated systems taking away your need for responsibility, eh?

    Assuming you tackled the herculean task of resetting your password, and are receiving many pats on the back, you will now need to regenerate your API key using `mix hex.user auth`.
    """
  end

  def owner_added(package, owners, owner) do
    owners
    |> Enum.each(fn(old_owner) ->
         owner.username
         |> owner_added_message(package.name)
         |> send_to(User.email(old_owner, :primary))
       end)
  end

  defp owner_added_message(user, package) do
    """
    #{user} has been added as an owner to #{package}
    """
  end

  def owner_removed(package, owners, owner) do
    owners
    |> Enum.each(fn(old_owner) ->
         owner.username
         |> owner_removed_message(package.name)
         |> send_to(User.email(old_owner, :primary))
       end)
  end

  defp owner_removed_message(user, package) do
    """
    #{user} has been removed as an owner from #{package}
    """
  end

  defp slack_rtm(), do: Application.get_env(:hexpm, :slack_rtm)
end
