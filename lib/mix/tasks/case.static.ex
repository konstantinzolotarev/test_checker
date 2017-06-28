defmodule Mix.Tasks.Check.Static do
  use Mix.Task

  @shortdoc "Runs static tournament test"
  def run(_), do: run_case()

  defp run_case() do
    IO.inspect "Running Static case"
    {:ok, _} = Application.ensure_all_started(:check_test)

    {:ok, _pid} = CheckTest.Case.Static.start_link()
    CheckTest.Case.Static.run()

  end
end
