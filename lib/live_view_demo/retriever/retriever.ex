defmodule LiveViewDemo.Retriever do
  @moduledoc "Retrieves Tweets from the Twitter API."

  use GenServer

  alias LiveViewDemoWeb.Retrieval

  @search Application.get_env(:live_view_demo, LiveViewDemo.Search)[:module]

  def start_link(_args) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def subscribe() do
    GenServer.call(__MODULE__, :subscribe)
  end

  @impl GenServer
  def init(_args) do
    :timer.send_interval(1000, self(), :tick)

    {:ok, nil}
  end

  @impl GenServer
  def handle_call(:subscribe, {pid, _ref}, nil) do
    remaining_tweets =
      [File.cwd!(), "priv", "fixtures", "favourites.json"]
      |> Path.join()
      |> File.read!()
      |> Jason.decode!()
      |> Util.Map.deep_atomize_keys()

    {:reply, :ok, %{subscribers: [pid], remaining_tweets: remaining_tweets}}
  end

  def handle_call(:subscribe, {pid, _ref}, state) do
    new_state = Map.put(state, :subscribers, [pid | state.subscribers])
    {:reply, :ok, new_state}
  end

  @impl GenServer
  def handle_info(:tick, nil) do
    {:noreply, nil}
  end

  def handle_info(:tick, state = %{remaining_tweets: []}) do
    {:noreply, state}
  end

  def handle_info(:tick, state = %{remaining_tweets: [loaded_tweet | remaining_tweets]}) do
    new_state =
      state
      |> Map.put(:remaining_tweets, remaining_tweets)
      |> loaded_tweets([loaded_tweet])
      |> notify_subscribers()

    {:noreply, new_state}
  end

  defp loaded_tweets(state, tweets) do
    @search.index(tweets)

    state
  end

  defp notify_subscribers(state) do
    retrieval_info = retrieval_info(state)

    Enum.each(state.subscribers, fn pid ->
      send(pid, {:retrieval_progress, retrieval_info})
    end)

    state
  end

  defp retrieval_info(%{remaining_tweets: []}), do: %Retrieval{}

  defp retrieval_info(state) do
    {:ok, total_count} = @search.total_count()

    %Retrieval{
      jobs: [
        %Retrieval.Job{
          channel: "Twitter Favorites",
          current: total_count,
          max: total_count + length(state.remaining_tweets)
        }
      ]
    }
  end
end
