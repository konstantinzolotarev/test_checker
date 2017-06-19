defmodule CheckTest.Case.Balance do

  use GenServer
  alias CheckTest.{Client, TestState}
  
  def start_link(state \\ %TestState{}) do
    GenServer.start_link(__MODULE__, state, name: __MODULE__)
  end

  def init(state) do
    {:ok, state}
  end

  def run do

  end

  def handle_info(msg, state) do
    
    {:noreply, state}
  end

  defp random_points do
    :rand.uniform(10) * 100
  end
end
