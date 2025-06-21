defmodule SongbasketPhoenix.Accounts do
  import Ecto.Query, warn: false
  alias SongbasketPhoenix.Repo

  alias SongbasketPhoenix.Accounts.{User, UserToken, UserNotifier}

  def get_user_by_email(email) when is_binary(email) do
    Repo.get_by(User, email: email)
  end

  def get_user!(id), do: Repo.get!(User, id)

  def register_user(attrs) do
    %User{}
    |> User.registration_changeset(attrs)
    |> upsert_user()
  end

  defp upsert_user(changeset) do
    update_fields =
      changeset.changes
      |> Map.drop([:spotify_id, :email])
      |> Map.to_list()

    Repo.insert(
      changeset,
      on_conflict: [set: update_fields],
      conflict_target: [:spotify_id, :email]
    )
  end

  def change_user_registration(%User{} = user, attrs \\ %{}) do
    User.registration_changeset(user, attrs, hash_password: false, validate_email: false)
  end

  def generate_user_session_token(user) do
    {token, user_token} = UserToken.build_session_token(user)
    Repo.insert!(user_token)
    token
  end

  def get_user_by_session_token(token) do
    {:ok, query} = UserToken.verify_session_token_query(token)
    Repo.one(query)
  end

  def delete_user_session_token(token) do
    Repo.delete_all(UserToken.by_token_and_context_query(token, "session"))
    :ok
  end
end
