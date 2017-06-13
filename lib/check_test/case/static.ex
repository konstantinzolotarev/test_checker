defmodule CheckTest.Case.Static do
  use GenServer
  alias CheckTest.{Client, TestState}

  def start_link(state \\ %TestState{}) do
    GenServer.start_link(__MODULE__, state, name: __MODULE__)
  end

  def init(state) do
    {:ok, %TestState{state | players: generate_players()}}
  end

  @doc """
  Will run test
  """
  def run do
    create_players
    |> announce_tournament
    |> fill_tournament
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
    with {:ok, _} <- join(state.tournament, "P5"),
         {:ok, _} <- join(state.tournament, "P1", ["P2", "P3", "P4"]),
         do: IO.inspect "Players joined tournament"

     {:reply, state, state}
  end

  @doc """
  Announce new tournament
  """
  defp announce_tournament(players) when length(players) == 5 do
    GenServer.call(__MODULE__, :announce_tournament)
  end

  @doc """
  Run async method to create each random players form state
  """
  defp create_players do
    GenServer.call(__MODULE__, :create_players)
  end

  @doc """
  fill tournament with players
  """
  defp fill_tournament(%TestState{tournament: id} = state) when id != nil do
    GenServer.call(__MODULE__, :join_players)
  end

  @doc """
  Join player into tournament
  """
  defp join(tournament, player, backers \\ []) do
    Client.join_tournament(tournament, player, backers)
  end

  @doc """
  Create a new player in system
  """
  defp create_player(%{player: id, points: points}) do
    {:ok, data} = Client.fund(id, points)
    data
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
