defmodule SongbasketPhoenix.Songbasket do
  def playlists(conn, _params) do
    {user_id, spotify_credentials} = params(conn)
    Spotify.Playlist.get_current_user_playlists(spotify_credentials)
  end

  defp params(conn) do
    user_id = conn.assigns[:current_user].spotify_id
    spotify_credentials = conn.assigns[:spotify_credentials]
    {user_id, spotify_credentials}
  end
end
