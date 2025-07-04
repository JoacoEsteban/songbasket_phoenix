defmodule SongbasketPhoenixWeb.UserSpotifyController do
  use SongbasketPhoenixWeb, :controller
  alias SongbasketPhoenix.Songbasket

  def user_playlists(conn, params) do
    conn
    |> Songbasket.playlists(params)
    |> case do
      {:ok, resp} -> json(conn, resp)
      {:error, _} -> json(conn, %{error: "Failed to fetch playlists"})
    end
  end

  def playlist_tracks(conn, %{"playlist_id" => id}) do
    conn
    |> Songbasket.playlist_tracks(id)
    |> case do
      {:ok, resp} -> json(conn, resp)
      {:error, _} -> json(conn, %{error: "Failed to fetch playlist tracks"})
    end
  end

  def me(conn, _params) do
    conn
    |> Songbasket.me()
    |> case do
      {:ok, resp} -> json(conn, resp)
      {:error, _} -> json(conn, %{error: "Failed to fetch user"})
    end
  end

  def album(conn, %{"album_id" => id}) do
    conn
    |> Songbasket.album(id)
    |> case do
      {:ok, resp} -> json(conn, resp)
      {:error, _} -> json(conn, %{error: "Failed to fetch album"})
    end
  end
end
