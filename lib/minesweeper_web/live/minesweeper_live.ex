defmodule MinesweeperWeb.MinesweeperLive do
  use Phoenix.LiveView

  @rows 16
  @columns 30
  @mine_count 99

  # possible mine states
  # unchecked
  # field
  # exploded-mine
  # flag
  # question

  # TODO: clean up in general

  defp new_game(socket, initial_x, initial_y) do
    assign(socket,
      rows: rows(initial_x, initial_y),
      flag_count: 0,
      mine_count: @mine_count,
      time: 0,
      game_status: "alive",
      game_started?: false,
      game_ended?: false
    )
  end

  defp generate_random_coordinates(mines, initial_x, initial_y) do
    random_x = Enum.random(1..@rows)
    random_y = Enum.random(1..@columns)

    final_coordinates =
      if [random_x, random_y] == [initial_x, initial_y] ||
           Enum.member?(mines, [random_x, random_y]) do
        generate_random_coordinates(mines, initial_x, initial_y)
      else
        [random_x, random_y]
      end

    final_coordinates
  end

  defp generate_mines(initial_x, initial_y) do
    mine_iterations = Enum.to_list(1..99)

    Enum.reduce(mine_iterations, [], fn _mine, mines ->
      [generate_random_coordinates(mines, initial_x, initial_y)] ++ mines
    end)
  end

  defp columns(mines, x) do
    for y <- 1..@columns, into: %{} do
      mine_value =
        if Enum.member?(mines, [x, y]) do
          1
        else
          nil
        end

      {y, [mine_value, "unchecked"]}
    end
  end

  defp rows(initial_x, initial_y) do
    mines = generate_mines(initial_x, initial_y)

    for x <- 1..@rows, into: %{} do
      {x, columns(mines, x)}
    end
  end

  defp won_game?(rows) do
    !Enum.any?(rows, fn row ->
      {_column_num, column_map} = row

      Enum.any?(column_map, fn column ->
        {_y, [mine_value, mine_state]} = column

        if mine_state == "unchecked" and mine_value == nil do
          true
        else
          false
        end
      end)
    end)
  end

  defp calculate_nearby_mines(rows, x_value, y_value) do
    nearby_values = [-1, 0, 1]

    Enum.reduce(nearby_values, 0, fn x, total_count ->
      Enum.reduce(nearby_values, total_count, fn y, column_count ->
        nearby_x = x_value + x
        nearby_y = y_value + y

        with %{^nearby_x => %{^nearby_y => [1, _mine_state]}} <- rows do
          column_count + 1
        else
          _ -> column_count
        end
      end)
    end)
  end

  defp calculate_new_columns_and_rows(mine, old_rows, x_value, y_value) do
    nearby_values = [-1, 0, 1]
    num_nearby_mines = calculate_nearby_mines(old_rows, x_value, y_value)

    if num_nearby_mines === 0 do
      Enum.reduce(nearby_values, old_rows, fn x, new_rows ->
        Enum.reduce(nearby_values, new_rows, fn y, rows ->
          nearby_x = x_value + x
          nearby_y = y_value + y

          with %{^nearby_x => %{^nearby_y => [nearby_mine = nil, "unchecked"]}} <- rows do
            new_columns = Map.put(rows[x_value], y_value, [mine, "field"])
            new_rows = Map.put(rows, x_value, new_columns)

            calculate_new_columns_and_rows(nearby_mine, new_rows, nearby_x, nearby_y)
          else
            _ ->
              rows
          end
        end)
      end)
    else
      new_columns = Map.put(old_rows[x_value], y_value, [mine, "mines#{num_nearby_mines}"])
      Map.put(old_rows, x_value, new_columns)
    end
  end

  defp reveal_all_mines(old_rows) do
    # when you lose the game, reveal all mines
    num_rows = Enum.to_list(1..@rows)
    num_columns = Enum.to_list(1..@columns)

    Enum.reduce(num_rows, old_rows, fn x, new_rows ->
      Enum.reduce(num_columns, new_rows, fn y, new_rows ->
        %{^x => %{^y => [mine, old_mine_state]}} = new_rows

        mine_states_to_reveal = ["flag", "question", "unchecked"]

        if mine == 1 and old_mine_state in mine_states_to_reveal do
          new_columns = Map.put(new_rows[x], y, [mine, "exploded-mine"])
          Map.put(new_rows, x, new_columns)
        else
          new_rows
        end
      end)
    end)
  end

  defp explode_mines(socket, x_value, y_value) do
    %{^x_value => %{^y_value => [mine, old_mine_state]}} = socket.assigns.rows

    # check if there's a mine
    case mine do
      # if there's no mine, and the field isn't marked, update the field
      # the updated field should display the number of nearby mines
      nil ->
        if old_mine_state != "flag" and old_mine_state != "question" do
          new_rows = calculate_new_columns_and_rows(mine, socket.assigns.rows, x_value, y_value)

          if won_game?(new_rows) do
            {:noreply,
             assign(socket,
               game_started?: false,
               game_ended?: true,
               game_status: "won",
               rows: new_rows
             )}
          else
            {:noreply,
             assign(socket,
               game_started?: true,
               rows: new_rows
             )}
          end
        else
          {:noreply,
           assign(socket,
             game_started?: true
           )}
        end

      1 ->
        # explode an unmarked mine, lose the game
        if old_mine_state != "flag" and old_mine_state != "question" do
          new_rows = reveal_all_mines(socket.assigns.rows)

          {:noreply,
           assign(socket,
             game_started?: false,
             game_ended?: true,
             game_status: "dead",
             rows: new_rows
           )}

          # if the mine is marked, do nothing
        else
          {:noreply,
           assign(socket,
             game_started?: true
           )}
        end

      # start the game
      _ ->
        {:noreply,
         assign(socket,
           game_started?: true
         )}
    end
  end

  defp mark_mines(socket, x_value, y_value) do
    %{^x_value => %{^y_value => [mine, old_mine_state]}} = socket.assigns.rows

    new_mine_state =
      case old_mine_state do
        "unchecked" -> "question"
        "flag" -> "unchecked"
        "question" -> "flag"
        _ -> old_mine_state
      end

    new_columns = Map.put(socket.assigns.rows[x_value], y_value, [mine, new_mine_state])
    new_rows = Map.put(socket.assigns.rows, x_value, new_columns)

    [new_flag_count, new_mine_count] =
      case new_mine_state do
        "unchecked" ->
          if socket.assigns.flag_count > 99 do
            [socket.assigns.flag_count - 1, socket.assigns.mine_count]
          else
            [socket.assigns.flag_count - 1, socket.assigns.mine_count + 1]
          end

        "flag" ->
          if socket.assigns.mine_count == 0 do
            [socket.assigns.flag_count + 1, socket.assigns.mine_count]
          else
            [socket.assigns.flag_count + 1, socket.assigns.mine_count - 1]
          end

        _ ->
          [socket.assigns.flag_count, socket.assigns.mine_count]
      end

    {:noreply,
     assign(socket,
       game_started?: true,
       flag_count: new_flag_count,
       mine_count: new_mine_count,
       rows: new_rows
     )}
  end

  defp schedule_tick(socket) do
    Process.send_after(self(), :tick, 1000)
    socket
  end

  def handle_event("mine-click", key, socket) do
    %{"shiftKey" => shiftKey, "x" => x, "y" => y} = key

    x_value = String.to_integer(x)
    y_value = String.to_integer(y)

    if shiftKey do
      mark_mines(socket, x_value, y_value)
    else
      # regenerate mines after first field is clicked to prevent first move ending the game
      socket =
        if socket.assigns.game_started? == false and (x_value != 1 or y_value != 1) do
          socket
          |> new_game(x_value, y_value)
        else
          socket
        end

      if socket.assigns.game_ended? == false and !shiftKey do
        explode_mines(socket, x_value, y_value)
      else
        {:noreply, socket}
      end
    end
  end

  def handle_event("restart-game", _key, socket) do
    # randomly generate mines
    new_socket =
      socket
      |> new_game(1, 1)

    {:noreply, new_socket}
  end

  def handle_info(:tick, socket) do
    new_socket = schedule_tick(socket)

    if new_socket.assigns.game_started? do
      new_time = if new_socket.assigns.time < 999, do: new_socket.assigns.time + 1, else: new_socket.assigns.time
      {:noreply, assign(new_socket, time: new_time)}
    else
      {:noreply, socket}
    end
  end

  def render(assigns) do
    MinesweeperWeb.PageView.render("index.html", assigns)
  end

  def mount(_session, socket) do
    # randomly generate mines
    socket =
      socket
      |> new_game(1, 1)

    if connected?(socket) do
      {:ok, schedule_tick(socket)}
    else
      {:ok, socket}
    end
  end
end
