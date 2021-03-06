defmodule CheckTest.Case.Static do
  use GenServer
  alias CheckTest.{Client, TestState}

  def start_link(state \\ %TestState{}) do
    GenServer.start_link(__MODULE__, state, name: __MODULE__)
  end

  def init(state) do
    IO.inspect self()
    {:ok, %TestState{state | players: generate_players()}}
  end

  @doc """
  Will run test
  """
  def run do
    create_players()
    |> announce_tournament()
    |> fill_tournament()
    |> results_tournament()
    |> players_balance()
  end

  @doc false
  def handle_call(:create_players, _from, %TestState{players: players} = state) do
    result = players
            |> Stream.map(&Task.async(fn -> create_player(&1) end))
            |> Enum.map(&Task.await(&1))
            |> Enum.filter(fn(v) -> v != nil end)

    {:reply, result, %TestState{state | players_created: result}}
  end

  @doc false
  def handle_call(:announce_tournament, _from, state) do
    {:ok, %{id: id, deposit: deposit}} = Client.announce_tournament(1, 1000)
    state = %TestState{state | tournament: id, deposit: deposit}
    {:reply, state, state}
  end

  @doc false
  def handle_call(:join_players, _from, state) do
     {:ok, _} = join(state.tournament, "P5")
     {:ok, _} = join(state.tournament, "P1", ["P2", "P3", "P4"])

     {:reply, state, state}
  end

  @doc false
  def handle_call(:result, _from, %TestState{tournament: id} = state) do
    winner = %Client.Winner{playerId: "P1", prize: 500}
    {:ok, _} = Client.tournament_results(id, [winner])
    {:reply, state, state}
  end

  def handle_call(:players_balance, _from, %TestState{players: players} = state) do
    players
    |> Stream.map(&Task.async(fn -> player_balance(&1) end))
    |> Enum.map(&Task.await(&1))
    |> Enum.filter(fn(v) -> v != nil end)
    {:reply, state, state}
  end

  def handle_info(msg, state) do
    IO.inspect msg
    {:noreply, state}
  end

  # """
  # Announce new tournament
  # """
  defp announce_tournament(players) when length(players) == 5 do
    # Process.sleep(1000)
    GenServer.call(__MODULE__, :announce_tournament)
  end

  # """
  # Run async method to create each random players form state
  # """
  defp create_players do
    # Process.sleep(1000)
    GenServer.call(__MODULE__, :create_players)
  end

  # """
  # fill tournament with players
  # """
  defp fill_tournament(%TestState{tournament: id}) when id != nil do
    # Process.sleep(1000)
    GenServer.call(__MODULE__, :join_players)
  end

  # """
  # Send an tournament results
  # """
  defp results_tournament(%TestState{tournament: id}) when id != nil do
    # Process.sleep(1000)
    GenServer.call(__MODULE__, :result)
  end

  defp players_balance(_state) do
    GenServer.call(__MODULE__, :players_balance)
  end

  # """
  # Join player into tournament
  # """
  defp join(tournament, player, backers \\ []) do
    Client.join_tournament(tournament, player, backers)
  end

  # """
  # Create a new player in system
  # """
  defp create_player(%{player: id, points: points}, pid \\ nil) do
    opts = case pid do
      nil -> []
      pid when is_pid(pid) -> [stream_to: pid]
      _ -> []
    end
    {:ok, data} = Client.fund(id, points, opts)
    data
  end

  defp player_balance(%{player: id}) do
    {:ok, %{balance: balance}} = Client.balance(id)
    IO.inspect "Player #{id} has balance: #{balance}"
    balance
  end

  defp generate_players() do
    [
      %{player: "P1", points: 300},
      %{player: "P2", points: 300},
      %{player: "P3", points: 300},
      %{player: "P4", points: 500},
      %{player: "P5", points: 1000}
    ]
  end
end
