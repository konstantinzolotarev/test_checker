defmodule CheckTest.Type.TournamentResult do  

  @derive [Poison.Encoder]
  defstruct tournamentId: "",
            winners: []
end
