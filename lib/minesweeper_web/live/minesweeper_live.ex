defmodule MinesweeperWeb.MinesweeperLive do
  use Phoenix.LiveView

  @rows 16
  @columns 30
  @mine_count 99

  # possible mine states
  # 0 unmarked
  # 1 flagged
  # 2 incorrectly flagged
  # 3 questioned

  defp new_game(socket) do
    assign(socket,
      rows: rows(),
      mine_count: @mine_count,
      time: 0,
      game_status: "alive",
      game_started?: false,
      flags_toggled?: false
    )
  end

  defp generate_mines() do
    for mines <- 1..@mine_count, into: %{} do
      {{Enum.random(1..16), Enum.random(1..30)}, 0}
    end
  end

  defp columns(x, mines) do
    for y <- 1..@columns, into: %{} do
      {y, Map.get(mines, {x, y})}
    end
  end

  defp rows() do
    mines = generate_mines()
    for x <- 1..@rows, into: %{} do
      {{x}, columns(x, mines)}
    end
  end

  defp schedule_tick(socket) do
    Process.send_after(self(), :tick, 1000)
    socket
  end

  def handle_event("mine-click", key, socket) do
    {:noreply,
    assign(socket,
      game_started?: true,
    )}
  end

  def handle_event("flag-click", key, socket) do
    %{flags_toggled?: flags_toggled} = socket.assigns


    {:noreply,
    assign(socket,
      flags_toggled?: !flags_toggled,
    )}
  end

  def handle_info(:tick, socket) do
    new_socket = schedule_tick(socket)
    if new_socket.assigns.game_started? do
      {:noreply, assign(new_socket, time: new_socket.assigns.time + 1)}
    else
      {:noreply, socket}
    end
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
