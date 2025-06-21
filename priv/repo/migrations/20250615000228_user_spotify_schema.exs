defmodule SongbasketPhoenix.Repo.Migrations.UserSpotifySchema do
  use Ecto.Migration

  def change do
    alter table(:users) do
      remove :hashed_password

      add :spotify_id, :string
      add :spotify_access_token, :string
      add :spotify_refresh_token, :string

      add :country, :string
      add :display_name, :string
      add :followers, :map
      add :href, :string
      add :images, :map
      add :product, :string
      add :type, :string
      add :uri, :string
    end

    drop_if_exists index(:users, [:email], name: :users_email_index)
    create unique_index(:users, [:spotify_id, :email])
  end
end
