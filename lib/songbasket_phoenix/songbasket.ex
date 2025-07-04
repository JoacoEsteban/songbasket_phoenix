defmodule SongbasketPhoenix.Songbasket do
  import Spotify
  require Protocol

  @ignored_global_keys [:available_markets]

  Protocol.derive(Jason.Encoder, Spotify.Track)
  Protocol.derive(Jason.Encoder, Spotify.Profile)
  Protocol.derive(Jason.Encoder, Spotify.Playlist)
  Protocol.derive(Jason.Encoder, Spotify.Album)
  Protocol.derive(Jason.Encoder, Spotify.Playlist.Track)
  Protocol.derive(Jason.Encoder, Spotify.Paging)

  def playlists(conn, _params) do
    conn
    |> exec(fn {user_id, spotify_credentials} ->
      Spotify.Playlist.get_current_user_playlists(spotify_credentials)
    end)
  end

  def playlist_tracks(conn, playlist_id) do
    conn
    |> exec(fn {user_id, spotify_credentials} ->
      Spotify.Playlist.get_playlist_tracks(spotify_credentials, user_id, playlist_id)
    end)
  end

  def album(conn, album_id) do
    conn
    |> exec(fn {user_id, spotify_credentials} ->
      Spotify.Album.get_album(spotify_credentials, album_id)
    end)
  end

  def me(conn) do
    conn
    |> exec(fn {user_id, spotify_credentials} ->
      Spotify.Profile.me(spotify_credentials)
    end)
  end

  defp params(conn) do
    user_id = conn.assigns[:current_user].spotify_id
    spotify_credentials = conn.assigns[:spotify_credentials]
    {user_id, spotify_credentials}
  end

  defp exec(conn, cb) do
    {user_id, spotify_credentials} = params(conn)

    case cb.({user_id, spotify_credentials}) do
      {:ok, %{"error" => %{"message" => "The access token expired", "status" => 401}}} ->
        {:ok, %Spotify.Credentials{} = new_creds} =
          Spotify.Authentication.refresh(spotify_credentials)

        {:ok, updated_user} =
          SongbasketPhoenix.Accounts.update_user_spotify_access_token(
            conn.assigns[:current_user],
            %{spotify_access_token: new_creds.access_token}
            |> IO.inspect(label: :creds)
          )

        conn
        |> Plug.Conn.assign(:current_user, updated_user)
        |> Plug.Conn.assign(:spotify_credentials, new_creds)
        |> exec(cb)

      {:ok, res} ->
        {:ok, res}
    end
  end
end
