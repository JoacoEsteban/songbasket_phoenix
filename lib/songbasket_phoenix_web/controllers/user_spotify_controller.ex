defmodule SongbasketPhoenixWeb.UserSpotifyController do
  use SongbasketPhoenixWeb, :controller
  alias SongbasketPhoenix.Songbasket

  def user_playlists(conn, params) do
    conn
    |> Songbasket.playlists(params)
    |> case do
      {:ok, resp, conn} -> json(conn, resp)
      {:error, _, conn} -> json(conn, %{error: "Failed to fetch playlists"})
    end
  end

  def playlist_update(conn, %{"playlist_id" => id} = params) do
    snapshot_id =
      params
      |> Map.get("snapshot_id")

    conn
    |> Songbasket.playlist_update(id, snapshot_id)
    |> case do
      {:ok, :not_modified, conn} -> conn |> put_status(:not_modified) |> json("")
      {:ok, resp, conn} -> json(conn, resp)
      {:error, _, conn} -> json(conn, %{error: "Failed to fetch playlist tracks"})
    end
  end

  def playlist_tracks(conn, %{"playlist_id" => id}) do
    conn
    |> Songbasket.playlist_tracks(id)
    |> case do
      {:ok, resp, conn} -> json(conn, resp)
      {:error, _, conn} -> json(conn, %{error: "Failed to fetch playlist tracks"})
    end
  end

  def me(conn, _params) do
    conn
    |> Songbasket.me()
    |> case do
      {:ok, resp, conn} -> json(conn, resp)
      {:error, _, conn} -> json(conn, %{error: "Failed to fetch user"})
    end
  end

  def album(conn, %{"album_id" => id}) do
    conn
    |> Songbasket.album(id)
    |> case do
      {:ok, resp, conn} -> json(conn, resp)
      {:error, _, conn} -> json(conn, %{error: "Failed to fetch album"})
    end
  end
end
