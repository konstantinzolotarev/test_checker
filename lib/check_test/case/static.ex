defmodule CheckTest.Case.Static do
  use GenServer
  alias CheckTest.{Client, TestState}

  def start_link(state \\ %TestState{}) do
    GenServer.start_link(__MODULE__, state, name: __MODULE__)
  end

  def init(state) do
    #Add players
    {:ok, state}
  end
end
