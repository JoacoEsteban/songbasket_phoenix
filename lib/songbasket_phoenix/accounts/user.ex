defmodule SongbasketPhoenix.Accounts.User do
  @derive {Jason.Encoder,
           only: [
             :id,
             :email,
             :spotify_id,
             :spotify_access_token,
             :spotify_refresh_token,
             :country,
             :display_name,
             :followers,
             :href,
             :images,
             :product,
             :type,
             :uri
           ]}

  use Ecto.Schema
  import Ecto.Changeset

  schema "users" do
    field :confirmed_at, :utc_datetime

    field :spotify_id, SongbasketPhoenix.EncryptedField, redact: true
    field :spotify_access_token, SongbasketPhoenix.EncryptedField, redact: true
    field :spotify_refresh_token, SongbasketPhoenix.EncryptedField, redact: true

    field :country, :string
    field :display_name, :string
    field :email, :string
    field :followers, :map
    field :href, :string
    field :images, :map
    field :product, :string
    field :type, :string
    field :uri, :string

    timestamps(type: :utc_datetime)
  end

  def spotify_access_token_changeset(user, attrs, opts \\ []) do
    user
    |> cast(attrs, [:spotify_access_token])
    |> validate_required([:spotify_access_token])
  end

  @doc """
  A user changeset for registration.

  It is important to validate the length of both email and password.
  Otherwise databases may truncate the email without warnings, which
  could lead to unpredictable or insecure behaviour. Long passwords may
  also be very expensive to hash for certain algorithms.

  ## Options

    * `:hash_password` - Hashes the password so it can be stored securely
      in the database and ensures the password field is cleared to prevent
      leaks in the logs. If password hashing is not needed and clearing the
      password field is not desired (like when using this changeset for
      validations on a LiveView form), this option can be set to `false`.
      Defaults to `true`.

    * `:validate_email` - Validates the uniqueness of the email, in case
      you don't want to validate the uniqueness of the email (like when
      using this changeset for validations on a LiveView form before
      submitting the form), this option can be set to `false`.
      Defaults to `true`.
  """
  def registration_changeset(user, attrs, opts \\ []) do
    user
    |> cast(attrs, [
      :spotify_id,
      :spotify_access_token,
      :spotify_refresh_token,
      :country,
      :display_name,
      :email,
      :followers,
      :href,
      :images,
      :product,
      :type,
      :uri
    ])
    |> validate_required([:spotify_id, :spotify_access_token, :spotify_refresh_token])
    |> unique_constraint(:email, name: :users_email_index)
    |> unique_constraint([:spotify_id, :email], name: :users_spotify_id_email_index)

    # |> validate_password(opts)
    # |> validate_email(opts)
  end

  defp validate_email(changeset, opts) do
    changeset
    |> validate_required([:email])
    |> validate_format(:email, ~r/^[^\s]+@[^\s]+$/, message: "must have the @ sign and no spaces")
    |> validate_length(:email, max: 160)
    |> maybe_validate_unique_email(opts)
  end

  defp validate_password(changeset, opts) do
    changeset
    |> validate_required([:password])
    |> validate_length(:password, min: 12, max: 72)
    # Examples of additional password validation:
    # |> validate_format(:password, ~r/[a-z]/, message: "at least one lower case character")
    # |> validate_format(:password, ~r/[A-Z]/, message: "at least one upper case character")
    # |> validate_format(:password, ~r/[!?@#$%^&*_0-9]/, message: "at least one digit or punctuation character")
    |> maybe_hash_password(opts)
  end

  defp validate_spotify_access_token(changeset, opts) do
    changeset
    # TODO check actual size
    |> validate_length(:password, min: 1, max: 200)
    |> maybe_hash_password(opts)
  end

  defp maybe_hash_password(changeset, opts) do
    hash_password? = Keyword.get(opts, :hash_password, true)
    password = get_change(changeset, :password)

    if hash_password? && password && changeset.valid? do
      changeset
      # If using Bcrypt, then further validate it is at most 72 bytes long
      |> validate_length(:password, max: 72, count: :bytes)
      # Hashing could be done with `Ecto.Changeset.prepare_changes/2`, but that
      # would keep the database transaction open longer and hurt performance.
      |> put_change(:hashed_password, Bcrypt.hash_pwd_salt(password))
      |> delete_change(:password)
    else
      changeset
    end
  end

  defp maybe_validate_unique_email(changeset, opts) do
    if Keyword.get(opts, :validate_email, true) do
      changeset
      |> unsafe_validate_unique(:email, SongbasketPhoenix.Repo)
      |> unique_constraint(:email)
    else
      changeset
    end
  end

  @doc """
  A user changeset for changing the email.

  It requires the email to change otherwise an error is added.
  """
  def email_changeset(user, attrs, opts \\ []) do
    user
    |> cast(attrs, [:email])
    |> validate_email(opts)
    |> case do
      %{changes: %{email: _}} = changeset -> changeset
      %{} = changeset -> add_error(changeset, :email, "did not change")
    end
  end

  @doc """
  A user changeset for changing the password.

  ## Options

    * `:hash_password` - Hashes the password so it can be stored securely
      in the database and ensures the password field is cleared to prevent
      leaks in the logs. If password hashing is not needed and clearing the
      password field is not desired (like when using this changeset for
      validations on a LiveView form), this option can be set to `false`.
      Defaults to `true`.
  """
  def password_changeset(user, attrs, opts \\ []) do
    user
    |> cast(attrs, [:password])
    |> validate_confirmation(:password, message: "does not match password")
    |> validate_password(opts)
  end

  @doc """
  Confirms the account by setting `confirmed_at`.
  """
  def confirm_changeset(user) do
    now = DateTime.utc_now() |> DateTime.truncate(:second)
    change(user, confirmed_at: now)
  end
end
