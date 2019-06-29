defmodule MinesweeperWeb.Router do
  use MinesweeperWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug Phoenix.LiveView.Flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", MinesweeperWeb do
    # Use the default browser stack
    pipe_through :browser

    # get "/", PageController, :index
    get "/", PageController, :game
  end

  # Other scopes may use custom stacks.
  # scope "/api", MinesweeperWeb do
  #   pipe_through :api
  # end
end
