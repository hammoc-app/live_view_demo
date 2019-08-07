defmodule LiveViewDemoWeb.DashboardLive do
  @moduledoc "A dashboard for your likes and bookmarks powered LiveView"

  use Phoenix.LiveView

  def render(assigns) do
    Phoenix.View.render(LiveViewDemoWeb.PageView, "dashboard.html",
      user: assigns.user,
      results: assigns.tweets,
      top_hashtags: assigns.top_hashtags,
      top_profiles: assigns.top_profiles,
      conn: assigns.socket
    )
  end

  def mount(_session, socket) do
    if connected?(socket), do: :timer.send_interval(1000, self(), :tick)

    remaining_tweets =
      [File.cwd!(), "priv", "fixtures", "favourites.json"]
      |> Path.join()
      |> File.read!()
      |> Jason.decode!()
      |> Util.Map.deep_atomize_keys()

    user = %{
      screen_name: "sasajuric",
      name: "Saša Jurić",
      profile_image_url:
        "http://pbs.twimg.com/profile_images/485776583542575104/PvpyGtOc_normal.jpeg"
    }

    new_socket =
      socket
      |> assign(:user, user)
      |> assign(:tweets, [])
      |> assign(:top_hashtags, [])
      |> assign(:top_profiles, [])
      |> assign(:loaded_tweets, [])
      |> assign(:remaining_tweets, remaining_tweets)

    {:ok, new_socket}
  end

  def handle_info(:tick, socket = %{assigns: %{remaining_tweets: []}}) do
    {:noreply, socket}
  end

  def handle_info(
        :tick,
        socket = %{assigns: %{remaining_tweets: [loaded_tweet | remaining_tweets]}}
      ) do
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
    |> update_top_hashtags()
    |> update_top_profiles()
  end

  defp update_tweets(socket) do
    tweets = socket.assigns.loaded_tweets
    assign(socket, tweets: tweets)
  end

  defp update_top_hashtags(socket) do
    top_hashtags =
      socket.assigns.tweets
      |> Enum.flat_map(& &1.entities.hashtags)
      |> Enum.map(& &1.text)
      |> Enum.uniq()
      |> Enum.sort()
      |> Enum.take(5)

    assign(socket, top_hashtags: top_hashtags)
  end

  defp update_top_profiles(socket) do
    top_profiles =
      socket.assigns.tweets
      |> Enum.map(& &1.user)
      |> Enum.uniq_by(& &1.screen_name)
      |> Enum.sort_by(& &1.followers_count)
      |> Enum.take(5)

    assign(socket, top_profiles: top_profiles)
  end
end
