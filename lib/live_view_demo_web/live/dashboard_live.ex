defmodule LiveViewDemoWeb.DashboardLive do
  @moduledoc "A dashboard for your likes and bookmarks powered LiveView"

  use Phoenix.LiveView

  def render(assigns) do
    IO.inspect(assigns.tweets)
    Phoenix.View.render(LiveViewDemoWeb.PageView, "dashboard.html", tweets: assigns.tweets, conn: assigns.socket)
  end

  def mount(_session, socket) do
    if connected?(socket), do: :timer.send_interval(1000, self(), :tick)

    remaining_tweets =
      [File.cwd!(), "priv", "fixtures", "favourites.json"]
      |> Path.join()
      |> File.read!()
      |> Jason.decode!()

    new_socket =
      socket
      |> assign(:tweets, [])
      |> assign(:loaded_tweets, [])
      |> assign(:remaining_tweets, remaining_tweets)

    {:ok, new_socket}
  end

  def handle_info(:tick, socket = %{assigns: %{remaining_tweets: []}}) do
    {:noreply, socket}
  end

  def handle_info(:tick, socket = %{assigns: %{remaining_tweets: [loaded_tweet | remaining_tweets]}}) do
    new_socket =
      socket
      |> assign(:remaining_tweets, remaining_tweets)
      |> loaded_tweets([loaded_tweet])

    {:noreply, new_socket}
  end

  defp loaded_tweets(socket, tweets) do
    socket
    |> update(:loaded_tweets, fn loaded_tweets -> loaded_tweets ++ tweets end)
    |> update_tweets()
  end

  defp update_tweets(socket) do
    tweets = socket.assigns.loaded_tweets
    assign(socket, tweets: tweets)
  end
end
