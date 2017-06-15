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
    IO.inspect Application.get_env(:check_test, :url, "http://localhost:4000/") <> url
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
  def process_request_body(body), do: Poison.encode!(body)

  @doc """
  Take points form player
  """
  @spec take(String.t, number) :: {:ok, %{player: String.t, points: number}} | {:error, any}
  def take(player, points) do

    case get("/take?playerId=#{player}&points=#{points}") do
      {:ok, %HTTPoison.Response{status_code: 200}} ->
        IO.inspect "Player #{player} take points #{points}"
        {:ok, %{player: player, points: points}}
      {:ok, %HTTPoison.Response{status_code: status_code, body: body}} ->
        IO.inspect "Player #{player} take points failed: #{status_code} - #{inspect body}"
        {:error, %{status_code: status_code, body: body}}
      {:error, err} ->
        IO.inspect "Player #{player} take points failed: #{inspect err}"
        {:error, err}
    end
  end

  @doc """
  Fund player with amount of points.
  In no player exist in DB this method should create a new player
  """
  @spec fund(String.t, number) :: {:ok, %{player: String.t, points: number}} | {:error, any}
  def fund(player, points, options \\ []) do

    case get("/fund?playerId=#{player}&points=#{points}", %{}, options) do
      {:ok, %HTTPoison.Response{status_code: 200}} ->
        IO.inspect "Player #{player} created with points #{points}"
        {:ok, %{player: player, points: points}}
      {:ok, %HTTPoison.AsyncResponse{}} ->
        IO.inspect "Async Player #{player} sent with points #{points}"
        {:ok, %{player: player, points: points}}
      {:ok, %HTTPoison.Response{status_code: 201}} ->
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
  @spec balance(String.t) :: {:ok, %{player: String.t, balance: number}} | {:error, any}
  def balance(player) do

    case get("/balance?playerId=#{player}") do
      {:ok, %HTTPoison.Response{status_code: 200, body: %{"balance" => balance}}} ->
        IO.inspect "Player #{player} balance: #{balance}"
        {:ok, %{player: player, balance: balance}}
      {:ok, %HTTPoison.Response{status_code: status_code, body: body}} ->
        IO.inspect "Player #{player} balance fetch failed: #{status_code} - #{inspect body}"
        {:error, %{status_code: status_code, body: body}}
      {:error, err} ->
        IO.inspect "Player #{player} balance fetch failed: #{inspect err}"
        {:error, err}
    end
  end

  @doc """
  Create a new tournament in system with default deposit
  """
  @spec announce_tournament(String.t, number) :: {:ok, %{id: String.t, deposit: number}} | {:error, any}
  def announce_tournament(id, deposit) do

    case get("/announceTournament?tournamentId=#{id}&deposit=#{deposit}") do
      {:ok, %HTTPoison.Response{status_code: 200}} ->
        IO.inspect "Tournament #{id} created with deposit #{deposit}"
        {:ok, %{id: id, deposit: deposit}}
      {:ok, %HTTPoison.Response{status_code: 201}} ->
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

  @spec join_tournament(String.t, String.t, [String.t]) :: {:ok, map} | {:error, any}
  def join_tournament(id, player, backers \\ []) do

    query = backers
            |> Enum.map(&("backerId=#{&1}"))
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

  @spec tournament_results(String.t, [%Winner{}]) :: {:ok, %{tournament: String.t, body: map}} | {:error, any}
  def tournament_results(id, winners) do

    payload = Poison.encode!(%{tournamentId: id, winners: winners})
    case post("/resultTournament", payload, [{"Content-Type", "application/json"}]) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        IO.inspect "Tournament #{id} results success: #{inspect body}"
        {:ok, %{tournament: id, body: body}}
      {:ok, %HTTPoison.Response{status_code: status_code, body: body}} ->
        IO.inspect "Tournament #{id} posting results failed: #{status_code} - #{inspect body}"
        {:error, %{status_code: status_code, body: body}}
      {:error, err} ->
        IO.inspect "Tournament #{id} posting results failed: #{inspect err}"
        {:error, err}
    end
  end

end
