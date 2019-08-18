defmodule MinesweeperWeb.PageController do
  use MinesweeperWeb, :controller

  def game(conn, _params) do
    Phoenix.LiveView.Controller.live_render(
      conn,
      MinesweeperWeb.MinesweeperLive,
      session: %{cookies: conn.cookies}
    )
  end
end
