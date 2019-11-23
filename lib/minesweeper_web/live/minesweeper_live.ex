defmodule MinesweeperWeb.MinesweeperLive do
  use Phoenix.LiveView

  @rows 16
  @columns 30
  @mine_count 99

  # possible mine states
  # exploded-mine
  # field
  # flag
  # incorrectly-marked-mine
  # mine
  # question

  defp new_game(socket) do
    assign(socket,
      rows: rows(),
      mine_count: @mine_count,
      time: 0,
      game_status: "alive",
      game_started?: false
    )
  end

  defp generate_mines() do
    for mines <- 1..@mine_count, into: %{} do
      {{Enum.random(1..16), Enum.random(1..30)}, 1}
    end
  end

  defp columns(x, mines) do
    for y <- 1..@columns, into: %{} do
      {y, [Map.get(mines, {x, y}), "mine"]}
    end
  end

  defp rows() do
    mines = generate_mines()
    for x <- 1..@rows, into: %{} do
      {x, columns(x, mines)}
    end
  end

  def explode_mines(socket, x, y) do
    x_value = String.to_integer(x)
    y_value = String.to_integer(y)

    %{^x_value => %{^y_value => [mine, old_mine_state]}} = socket.assigns.rows

    case mine do
      nil -> if (old_mine_state != "flag" || old_mine_state != "question") do
        # TODO: calculate mines around the field, display number instead of empty field
        new_columns = Map.put(socket.assigns.rows[x_value], y_value, [mine, "field"])
        new_rows = Map.put(socket.assigns.rows, x_value, new_columns)

        {:noreply,
        assign(socket,
          game_started?: false,
          rows: new_rows
        )}
        else
          {:noreply,
        assign(socket,
          game_started?: true,
        )}
        end
      1 ->
        # explode an unmarked mine, lose the game
        if (old_mine_state != "flag" || old_mine_state != "question") do
        new_columns = Map.put(socket.assigns.rows[x_value], y_value, [mine, "exploded-mine"])
        new_rows = Map.put(socket.assigns.rows, x_value, new_columns)

        {:noreply,
        assign(socket,
          game_started?: false,
          rows: new_rows
        )}
        else
          {:noreply,
        assign(socket,
          game_started?: true,
        )}
        end

      _ ->
        {:noreply,
        assign(socket,
          game_started?: true,
        )}
    end
  end

  defp mark_mines(socket, x, y) do
    x_value = String.to_integer(x)
    y_value = String.to_integer(y)

    %{^x_value => %{^y_value => [mine, old_mine_state]}} = socket.assigns.rows

    new_mine_state = case old_mine_state do
      "mine" -> "question"
      "flag" -> "mine"
      "question" -> "flag"
    end

    new_columns = Map.put(socket.assigns.rows[x_value], y_value, [mine, new_mine_state])
    new_rows = Map.put(socket.assigns.rows, x_value, new_columns)

    {:noreply, assign(socket, rows: new_rows)}
  end

  defp schedule_tick(socket) do
    Process.send_after(self(), :tick, 1000)
    socket
  end

  def handle_event("mine-click", key, socket) do
    %{"shiftKey" => shiftKey, "x" => x, "y" => y} = key
    if shiftKey do
      mark_mines(socket, x, y)
    else
      # TODO: only explode mines if the game is started
      explode_mines(socket, x, y)
    end
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
