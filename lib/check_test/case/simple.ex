defmodule CheckTest.Case.Simple do
  use GenServer

  alias CheckTest.{Client, TestState}

  def start_link(state \\ %TestState{}) do
    GenServer.start_link(__MODULE__, state, name: __MODULE__)
  end

  def init(state) do
    {:ok, %TestState{state | players: generate_players()}}
  end

  @doc """
  Generate new 7 players with random points from 1000 - 10000
  """
  defp generate_players() do
    1..8
    |> Enum.map(&(%{player: "P#{&1}", points: :rand.uniform(10) * 1000}))
  end

  @doc """
  Run async method to create each random players form state
  """
  def create_players do
    GenServer.cast(__MODULE__, :create_players)
  end

  @doc """
  Create a new player in system
  """
  def create_player(%{player: id, points: points}) do
    case Client.fund(id, points) do

      {:ok, %HTTPoison.Response{status_code: 200}} ->
        IO.inspect "Player #{id} created with points #{points}"
        %{player: id, points: points}
      {:ok, %HTTPoison.Response{status_code: status_code, body: body}} ->
        IO.inspect "Player #{id} was not created: #{status_code} - #{inspect body}"
        nil
      {:error, err} ->
        IO.inspect "Player #{id} was not created: #{inspect err}"
        nil
    end
  end

  def handle_cast(:create_players, %TestState{players: players} = state) do
    result = players
            |> Stream.map(&Task.async(CheckTest.Case.Simple, :create_player, [&1]))
            |> Enum.map(&Task.await(&1))
            |> Enum.filter(fn(v) -> v != nil end)

    {:noreply, %TestState{state | players_created: result}}
  end

end
