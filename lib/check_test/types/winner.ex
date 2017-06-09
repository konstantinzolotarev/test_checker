defmodule CheckTest.Type.Winner do  

  @derive [Poison.Encoder]
  defstruct [:playerId, :prize]
end
