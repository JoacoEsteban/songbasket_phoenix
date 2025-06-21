defmodule SongbasketPhoenixWeb.UserRegistrationController do
  use SongbasketPhoenixWeb, :controller

  alias SongbasketPhoenix.Accounts
  alias SongbasketPhoenix.Accounts.User
  alias SongbasketPhoenixWeb.UserAuth

  def spotify_start_authorization(conn, _params) do
    redirect(conn, external: Spotify.Authorization.url())
  end

  def spotify_authorize(conn, params) do
    {:ok, credentials} =
      Spotify.Authentication.authenticate(%Spotify.Credentials{refresh_token: nil}, params)

    {:ok, user} =
      credentials
      |> Spotify.Profile.me()

    case Accounts.register_user(
           user
           |> Map.delete(:__struct__)
           |> Map.delete(:__meta__)
           |> Map.delete(:associations)
           |> Map.put(:images, %{})
           |> Map.merge(%{
             spotify_access_token: credentials.access_token,
             spotify_refresh_token: credentials.refresh_token,
             spotify_id: user.id
           })
         ) do
      {:ok, user} ->
        conn
        |> UserAuth.log_in_user(user)
        |> send_resp(:ok, "User created successfully.")

      {:error, %Ecto.Changeset{} = changeset} ->
        conn
        |> send_resp(:bad_request, "Error when creating user")
    end
  end

  def new(conn, _params) do
    changeset = Accounts.change_user_registration(%User{})
    render(conn, :new, changeset: changeset)
  end

  def create(conn, %{"user" => user_params}) do
    case Accounts.register_user(user_params) do
      {:ok, user} ->
        {:ok, _} =
          Accounts.deliver_user_confirmation_instructions(
            user,
            &url(~p"/users/confirm/#{&1}")
          )

        conn
        |> put_flash(:info, "User created successfully.")
        |> UserAuth.log_in_user(user)

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, :new, changeset: changeset)
    end
  end
end
