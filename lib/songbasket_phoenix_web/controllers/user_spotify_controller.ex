defmodule SongbasketPhoenixWeb.UserSpotifyController do
  use SongbasketPhoenixWeb, :controller
  alias SongbasketPhoenix.Songbasket

  def user_playlists(conn, _params) do
    conn
    |> Songbasket.playlists(_params)
    |> case do
      {:ok, resp} -> Jason.encode!(resp)
      {:error, _} -> Jason.encode!(%{error: "Failed to fetch playlists"})
    end
  end
end
