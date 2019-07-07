defmodule MinesweeperWeb.MinesweeperLive do
  use Phoenix.LiveView

  defp new_game(socket) do
    assign(socket,
      rows: rows(),
      mine_count: 99,
      time: 0,
      game_status: "alive"
    )
  end

  @rows 16
  @columns 30

  defp columns() do
    for y <- 1..@columns, into: %{} do
      {y, "mine"}
    end
  end

  defp rows() do
    for x <- 1..@rows, into: %{} do
      {{x}, columns()}
    end
  end

  defp schedule_tick(socket) do
    Process.send_after(self(), :tick, 1000)
    socket
  end

  def handle_info(:tick, socket) do
    {:noreply,
    assign(socket,
      time: socket.assigns.time + 1
    )}
  end

  def render(assigns) do
    MinesweeperWeb.PageView.render("index.html", assigns)
  end

  def mount(session, socket) do
    socket =
      socket
      |> new_game()

    if connected?(socket) do
      {:ok, schedule_tick(socket)}
    else
      {:ok, socket}
    end
  end
end
