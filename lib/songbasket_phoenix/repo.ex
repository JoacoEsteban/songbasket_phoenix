defmodule SongbasketPhoenix.Repo do
  use Ecto.Repo,
    otp_app: :songbasket_phoenix,
    adapter: Ecto.Adapters.SQLite3
end
