defmodule LiveSecretWeb.Router do
  use LiveSecretWeb, :router

  pipeline :browser do
    plug(:accepts, ["html"])
    plug(:fetch_session)
    plug(:fetch_live_flash)
    plug(:put_root_layout, {LiveSecretWeb.Layouts, :root})
    plug(:protect_from_forgery)
    plug(:put_secure_browser_headers)
  end

  pipeline :api do
    plug(:accepts, ["json"])
  end

  scope "/", LiveSecretWeb do
    pipe_through(:browser)

    live_session :user, on_mount: LiveSecretWeb.InitAssigns do
      live("/", PageLive, :create)
      live("/admin/:id", PageLive, :admin)
      live("/secret/:id", PageLive, :receiver)
    end
  end

  # Enables LiveDashboard only for development
  #
  # If you want to use the LiveDashboard in production, you should put
  # it behind authentication and allow only admins to access it.
  # If your application does not have an admins-only section yet,
  # you can use Plug.BasicAuth to set up some basic authentication
  # as long as you are also using SSL (which you should anyway).
  if Mix.env() in [:dev, :test] do
    import Phoenix.LiveDashboard.Router

    scope "/" do
      pipe_through(:browser)

      live_dashboard("/dashboard", metrics: LiveSecretWeb.Telemetry)
    end
  end
end
