defmodule CheckTest.Case.Balance do

  use GenServer
  alias CheckTest.{Client}
  
  defmodule TestState do  
  
    defstruct player: "P1",
              balance: 0,
              active_tasks: 0,
              tasks: %{}

  end 

  defmodule Task do 
    defstruct status: 0,
              amount: 0
  end

  def start_link(state \\ %TestState{}) do
    GenServer.start_link(__MODULE__, state, name: __MODULE__)
  end

  @doc false
  def init(%TestState{player: player} = state) do
    {:ok, %{balance: balance}} = Client.balance(player)
    IO.inspect({player, balance})
    {:ok, %TestState{state | balance: balance}}
  end

  @doc """
  Run set of iterations fro different fund/take operations
  """
  def run(max \\ 100) do
    for _ <- 1..max, do: shoot()  
  end
  
  @doc"""
  Create a random amount and send a request to fund/take this amount from player
  """
  def shoot do
    case :rand.uniform(2) do  
      1 -> fund()
      2 -> take()
    end
  end

  @doc """
  Get currect GenServer state
  """
  def state do
    GenServer.call(__MODULE__, :state)
  end

  def handle_call(:state, _from, state) do
    {:reply, state, state}
  end

  @doc false
  def handle_call({:fund, amount}, _from, %{player: player, tasks: tasks, active_tasks: active_tasks} = state) do
    IO.inspect "Fund: #{amount}"
    {:ok, id} = Client.fund(player, amount, [stream_to: __MODULE__])
    {:reply, state, %TestState{state | tasks: Map.put(tasks, id, %Task{amount: amount}), active_tasks: active_tasks + 1}}
  end

  @doc false
  def handle_call({:take, amount}, _from, %{player: player, tasks: tasks, active_tasks: active_tasks} = state) do  
    IO.inspect "Take: #{amount}"
    {:ok, id} = Client.take(player, amount, [stream_to: __MODULE__])
    {:reply, state, %TestState{state | tasks: Map.put(tasks, id, %Task{amount: amount * -1}), active_tasks: active_tasks + 1}}
  end

  def handle_info(%HTTPoison.AsyncStatus{code: 200, id: id}, state), do: success(id, 200, state)
  
  def handle_info(%HTTPoison.AsyncStatus{code: 201, id: id}, state), do: success(id, 201, state)

  def handle_info(%HTTPoison.AsyncStatus{code: code, id: id}, state), do: failure(id, code, state)

  def handle_info(%HTTPoison.AsyncEnd{}, %TestState{active_tasks: active_tasks} = state) do
    if active_tasks == 1, do: send_finish()
    {:noreply, %TestState{state | active_tasks: active_tasks - 1}}
  end

  def handle_info(:finsihed, %{balance: balance, player: player} = state) do
    IO.inspect "Finished all tesks"
    IO.inspect "Result: #{balance}"

    {:ok, %{balance: received}} = Client.balance(player)
    IO.inspect "Balance from app: #{received}"
    {:noreply, state}
  end 

  def handle_info(_msg, state) do
    {:noreply, state}
  end

  defp failure(id, code, %{tasks: tasks} = state) do
    
    case Map.get(tasks, id) do  
      nil -> {:noreply, state}
      value -> 
        {:noreply, %TestState{state | tasks: Map.put(tasks, id, %Task{value | status: code})}}
    end
  end

  defp success(id, code, %{tasks: tasks, balance: balance} = state) do
    
    case Map.get(tasks, id) do  
      nil -> {:noreply, state}
      value -> 
        {:noreply, %TestState{state | tasks: Map.put(tasks, id, %Task{value | status: code}), balance: balance + value.amount}}
    end
  end
  
  defp send_finish do
    send(__MODULE__, :finsihed)
  end

  defp fund do
    GenServer.call(__MODULE__, {:fund, random_points()})
  end

  defp take do
    GenServer.call(__MODULE__, {:take, random_points()})
  end

  defp random_points do
    :rand.uniform(10) * 100
  end
end
