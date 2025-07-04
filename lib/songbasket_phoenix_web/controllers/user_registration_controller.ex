defmodule SongbasketPhoenixWeb.UserRegistrationController do
  @token_name "songbasket_one_time_token"
  @secret_name "songbasket_one_time_secret"
  use SongbasketPhoenixWeb, :controller

  alias SongbasketPhoenix.Accounts
  alias SongbasketPhoenix.Accounts.User
  alias SongbasketPhoenixWeb.UserAuth
  alias SongbasketPhoenix.Auth.Store, as: Store

  @authorization_app_redirect_url "songbasket://ok"

  def client_request_auth(conn, _params) do
    {:ok, {token, secret}} = Store.new_token()

    conn
    |> json(%{token: token, secret: secret})
  end

  def client_retrieve_token(conn, params) do
    [token] = get_req_header(conn, @token_name)
    [secret] = get_req_header(conn, @secret_name)
    IO.inspect(conn)
    IO.inspect(conn.req_headers)
    IO.inspect(token)
    IO.inspect(secret)

    unless [token, secret] |> Enum.any?(&is_nil/1) do
      case Store.retrieve_user_token({token, secret}) do
        {:ok, {token, spotify_user_id}} ->
          token
          |> IO.inspect(label: "will send user token:")

          conn
          |> json(%{token: token, spotify_user_id: spotify_user_id})

        {:error, :not_found} ->
          IO.inspect("not found")

          conn
          |> put_status(:unauthorized)
          |> json(%{error: "Your token might have expired. Try logging in again."})

        _ ->
          conn
          |> put_status(:internal_server_error)
          |> json(%{error: "Internal server error"})
      end
    else
      conn
      |> put_status(:bad_request)
      |> json(%{error: "Missing token or secret"})
    end
  end

  def spotify_start_authorization(conn, params) do
    # look for token
    token = params[@token_name]
    # validate it's stored
    case Store.is_valid?(token) do
      true ->
        conn
        # put it as a cookie
        |> put_resp_cookie(@token_name, token)
        # redirect
        |> redirect(external: Spotify.Authorization.url())

      false ->
        conn
        # put 403
        |> put_status(:forbidden)
        |> json(%{error: "Unauthorized"})
    end
  end

  def spotify_authorize(conn, params) do
    # look for cookie token
    token =
      conn.req_cookies[@token_name]

    # fetch corresponding store
    true = Store.is_valid?(token)

    {:ok, credentials} =
      Spotify.Authentication.authenticate(%Spotify.Credentials{refresh_token: nil}, params)

    {:ok, spotify_user} =
      credentials
      |> Spotify.Profile.me()

    case Accounts.register_user(
           spotify_user
           |> Map.delete(:__struct__)
           |> Map.delete(:__meta__)
           |> Map.delete(:associations)
           |> Map.put(:images, %{})
           |> Map.merge(%{
             spotify_access_token: credentials.access_token,
             spotify_refresh_token: credentials.refresh_token,
             spotify_id: spotify_user.id
           })
         ) do
      {:ok, user} ->
        conn
        |> put_session(:user_return_external, @authorization_app_redirect_url)
        |> UserAuth.log_in_user(user, %{
          storage_public_key: token,
          spotify_user_id: spotify_user.id
        })

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
