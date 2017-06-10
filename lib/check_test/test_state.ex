defmodule TestState do

  defstruct players: [],
            players_created: [],
            tournament: :rand.uniform(100),
            deposit: 1000
end
