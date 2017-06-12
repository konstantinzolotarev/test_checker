defmodule CheckTest.Client do

  use HTTPoison.Base

  defmodule Winner do
    @moduledoc """
    Structure for tournament results input in winners field
    """
    @derive [Poison.Encoder]
    @enforce_keys [:playerId, :prize]
    defstruct [:playerId, :prize]
  end

  @doc false
  def process_url(url) do
    Application.get_env(:check_test, :url, "http://localhost:4000/") <> url
  end

  @doc false
  def process_response_body(body) do
    case Poison.decode(body) do
      {:ok, parsed} -> parsed
      {:error, _} -> body
      {:error, _, _} -> body
    end
  end

  @doc false
  def process_request_body(body) when is_binary(body), do: body

  @doc false
  def process_request_body(body) do
    Poison.encode!(body)
  end

  @doc """
  Take points form player
  """
  @spec take(String.t, number) :: {:ok, %HTTPoison.Response{}} | {:error, %HTTPoison.Error{}}
  def take(player, points) do

    get("/take?playerId=#{player}&points=#{points}")
  end

  @doc """
  Fund player with amount of points.
  In no player exist in DB this method should create a new player
  """
  @spec fund(String.t, number) :: {:ok, %HTTPoison.Response{}} | {:error, %HTTPoison.Error{}}
  def fund(player, points) do

    case get("/fund?playerId=#{player}&points=#{points}") do
      {:ok, %HTTPoison.Response{status_code: 200}} ->
        IO.inspect "Player #{player} created with points #{points}"
        {:ok, %{player: player, points: points}}
      {:ok, %HTTPoison.Response{status_code: status_code, body: body}} ->
        IO.inspect "Player #{player} was not created: #{status_code} - #{inspect body}"
        {:error, %{status_code: status_code, body: body}}
      {:error, err} ->
        IO.inspect "Player #{player} was not created: #{inspect err}"
        {:error, err}
    end
  end

  @doc """
  Get player current balance. If no player exist error have to be returned
  """
  @spec balance(String.t) :: {:ok, %HTTPoison.Response{}} | {:error, %HTTPoison.Error{}}
  def balance(player) do

    get("/balance?playerId=#{player}")
  end

  @doc """
  Create a new tournament in system with default deposit
  """
  @spec announce_tournament(String.t, number) :: {:ok, %HTTPoison.Response{}} | {:error, %HTTPoison.Error{}}
  def announce_tournament(id, deposit) do

    case get("/announceTournament?tournamentId=#{id}&deposit=#{deposit}") do
      {:ok, %HTTPoison.Response{status_code: 200}} ->
        IO.inspect "Tournament #{id} created with deposit #{deposit}"
        {:ok, %{id: id, deposit: deposit}}
      {:ok, %HTTPoison.Response{status_code: status_code, body: body}} ->
        IO.inspect "Tournament #{id} was not created: #{status_code} - #{inspect body}"
        {:error, %{status_code: status_code, body: body}}
      {:error, err} ->
        IO.inspect "Tournament #{id} was not created: #{inspect err}"
        {:error, err}
    end
  end

  @spec join_tournament(String.t, String.t, [String.t]) :: {:ok, %HTTPoison.Response{}} | {:error, %HTTPoison.Error{}}
  def join_tournament(id, player, backers \\ []) do

    query = backers
            |> Enum.map(&("bakerId=#{&1}"))
            |> Enum.join("&")

    case get("/joinTournament?tournamentId=#{id}&playerId=#{player}&#{query}") do
      {:ok, %HTTPoison.Response{status_code: 200}} ->
        IO.inspect "Player #{player} Joined tournament #{id} with bakers #{inspect backers}"
        {:ok, %{player: player, backers: backers, tournament: id}}
      {:ok, %HTTPoison.Response{status_code: status_code, body: body}} ->
        IO.inspect "Player #{player} failed to join: #{status_code} - #{inspect body}"
        {:error, %{status_code: status_code, body: body}}
      {:error, err} ->
        IO.inspect "Player #{player} failed to join: #{inspect err}"
        {:error, err}
    end
  end

  @spec tournament_results(String.t, [%Winner{}]) :: {:ok, %HTTPoison.Response{}} | {:error, %HTTPoison.Error{}}
  def tournament_results(id, winners) do

    payload = Poison.encode!(%{tournamentId: id, winners: winners})
    post("/resultTournament", payload, [{"Content-Type", "application/json"}])
  end

end
