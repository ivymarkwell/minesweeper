defmodule MinesweeperWeb.PageController do
  use MinesweeperWeb, :controller

  def index(conn, _params) do
    render conn, "index.html"
  end

  def game(conn, _params) do
    Phoenix.LiveView.Controller.live_render(
      conn,
      MinesweeperWeb.MinesweeperLive,
      session: %{cookies: conn.cookies}
    )
  end
end
