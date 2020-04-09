defmodule MinesweeperWeb.PageController do
  use MinesweeperWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html")
  end
end
