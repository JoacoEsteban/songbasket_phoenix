defmodule SongbasketPhoenixWeb.Router do
  use SongbasketPhoenixWeb, :router

  import SongbasketPhoenixWeb.UserAuth

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {SongbasketPhoenixWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :fetch_current_user
  end

  pipeline :api do
    plug :accepts, ["json"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :fetch_current_user
  end

  scope "/", SongbasketPhoenixWeb do
    pipe_through :browser

    get "/", PageController, :home
  end

  # Other scopes may use custom stacks.
  # scope "/api", SongbasketPhoenixWeb do
  #   pipe_through :api
  # end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:songbasket_phoenix, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: SongbasketPhoenixWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end

  ## Authentication routes
  scope "/", SongbasketPhoenixWeb do
    pipe_through [:browser]

    get "/spotify_login", UserRegistrationController, :spotify_start_authorization
    get "/handle_authorization", UserRegistrationController, :spotify_authorize
  end

  scope "/api", SongbasketPhoenixWeb do
    pipe_through [:api, :require_authenticated_user]

    get "/playlists", UserSpotifyController, :user_playlists
  end

  scope "/", SongbasketPhoenixWeb do
    pipe_through [:browser]

    delete "/users/log_out", UserSessionController, :delete
  end
end
