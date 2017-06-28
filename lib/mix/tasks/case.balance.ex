defmodule Mix.Tasks.Case.Balance do
  use Mix.Task

  @shortdoc "Runs PLayer Balance test"
  def run([player | _]), do: run_case(player)
  def run(_), do: run_case("P1")

  defp run_case(player) do
    IO.inspect "Running Balance case for player: #{player}"
    {:ok, _} = Application.ensure_all_started(:check_test)

    {:ok, _pid} = CheckTest.Case.Balance.start_link()

    CheckTest.Case.Balance.run(500)

  end
end
