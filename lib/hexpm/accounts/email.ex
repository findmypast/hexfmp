defmodule Hexpm.Accounts.Email do
  use Hexpm.Web, :schema

  schema "emails" do
    field :email, :string
    field :verified, :boolean, default: false
    field :primary, :boolean, default: false
    field :public, :boolean, default: false
    field :verification_key, :string

    belongs_to :user, User

    timestamps()
  end

  @email_regex ~r"^.+@.+\..+$"
  @slack_regex ~r"^[@#]\S+$"

  def changeset(email, type, params, verified? \\ not Application.get_env(:hexpm, :user_confirm))

  def changeset(email, :first, params, verified?) do
    changeset(email, :create, params, verified?)
    |> put_change(:primary, true)
    |> put_change(:public, true)
  end

  def changeset(email, :create, params, verified?) do
    if Application.get_env(:hexpm, :slack) do
      cast(email, params, ~w(email))
      |> validate_required(~w(email)a)
      |> update_change(:email, &String.downcase/1)
      |> validate_format(:email, @slack_regex, message: "Slack target must start with an @ or # and contain no spaces.")
      |> validate_confirmation(:email, message: "does not match slack target")
      |> validate_verified_email_exists(:email, message: "slack target already in use")
      |> unique_constraint(:email, name: "emails_email_key")
      |> unique_constraint(:email, name: "emails_email_user_key")
      |> put_change(:verified, verified?)
      |> put_change(:verification_key, Auth.gen_key())
    else
      cast(email, params, ~w(email))
      |> validate_required(~w(email)a)
      |> update_change(:email, &String.downcase/1)
      |> validate_format(:email, @email_regex)
      |> validate_confirmation(:email, message: "does not match email")
      |> validate_verified_email_exists(:email, message: "email already in use")
      |> unique_constraint(:email, name: "emails_email_key")
      |> unique_constraint(:email, name: "emails_email_user_key")
      |> put_change(:verified, verified?)
      |> put_change(:verification_key, Auth.gen_key())
    end
  end

  def verify?(nil, _key),
    do: false
  def verify?(%Email{verification_key: verification_key}, key),
    do: verify?(verification_key, key)
  def verify?(verification_key, key),
    do: Comeonin.Tools.secure_check(verification_key, key)

  def verify(email) do
    change(email, %{verified: true, verification_key: nil})
    |> unique_constraint(:email, name: "emails_email_key", message: "email already in use")
  end

  def toggle_primary(email, flag) do
    change(email, %{primary: flag})
  end

  def toggle_public(email, flag) do
    change(email, %{public: flag})
  end

  def order_emails(emails) do
    Enum.sort_by(emails, &[not &1.primary, not &1.public, not &1.verified, -&1.id])
  end
end
