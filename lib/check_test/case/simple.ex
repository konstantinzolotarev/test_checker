defmodule CheckTest.Case.Simple do  
  use GenServer

  alias CheckTest.Client

  defmodule TestState do  
  
    defstruct players: [],
              tournament: ""
  end

  def start_link(state \\ %TestState{}) do 
    GenServer.start_link(__MODULE__, state, name: __MODULE__)
  end

  def init(state) do 
    {:ok, %TestState{state | players: create_players()}}
  end

  def create_players() do
    1..8
    |> Enum.map(%{player: "P#{&1}", points: :rand.uniform(10) * 100})
  end

end
