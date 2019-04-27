defmodule MinesweeperWeb.MinesweeperLive do
    use Phoenix.LiveView

    def render(assigns) do
        MinesweeperWeb.PageView.render("index.html", assigns)
    end
  end
