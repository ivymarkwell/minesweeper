defmodule MinesweeperWeb.Router do
  use MinesweeperWeb, :router

  import Phoenix.LiveView.Router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  scope "/", MinesweeperWeb do
    # Use the default browser stack
    pipe_through :browser

    live "/", MinesweeperLive, layout: {MinesweeperWeb.LayoutView, "root.html"}
  end
end
