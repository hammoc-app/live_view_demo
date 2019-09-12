defmodule LiveViewDemoWeb.DashboardLive do
  @moduledoc "A dashboard for your likes and bookmarks powered LiveView"

  use Phoenix.LiveView

  alias LiveViewDemoWeb.Router.Helpers, as: Routes
  alias LiveViewDemoWeb.Retrieval
  alias LiveViewDemo.Search.Facets

  @search Application.get_env(:live_view_demo, LiveViewDemo.Search)[:module]

  def render(assigns) do
    Phoenix.View.render(LiveViewDemoWeb.PageView, "dashboard.html",
      user: assigns.user,
      top_hashtags: assigns.top_hashtags,
      top_profiles: assigns.top_profiles,
      facets: assigns.facets,
      autocomplete: assigns.autocomplete,
      conn: assigns.socket,
      retrieval: assigns.retrieval,
      paginator: assigns.paginator
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
      |> assign(:top_hashtags, [])
      |> assign(:top_profiles, [])
      |> assign(:loaded_tweets, [])
      |> assign(:remaining_tweets, remaining_tweets)
      |> assign(:facets, %Facets{})
      |> assign(:autocomplete, nil)
      |> assign(:retrieval, %Retrieval{})
      |> update_tweets()

    {:ok, new_socket}
  end

  def handle_params(params, _uri, socket) do
    new_socket =
      socket
      |> assign(:facets, Facets.from_params(params))
      |> update_tweets()
      |> update_top_hashtags()
      |> update_top_profiles()

    {:noreply, new_socket}
  end

  def handle_event("search-and-autocomplete", params, socket) do
    new_socket = search(socket, params, params["q"])

    {:noreply, new_socket}
  end

  def handle_event("search", params, socket) do
    new_socket = search(socket, params, nil)

    {:noreply, new_socket}
  end

  defp search(socket, form_params, autocomplete) do
    url_params = form_params |> Facets.from_params() |> Facets.to_url_params()
    path = Routes.live_path(socket, __MODULE__, url_params)

    socket
    |> update_autocomplete(autocomplete)
    |> live_redirect(to: path)
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
    :ok = @search.index(tweets)

    socket
    |> update(:loaded_tweets, fn loaded_tweets -> loaded_tweets ++ tweets end)
    |> update_tweets()
    |> update_top_hashtags()
    |> update_top_profiles()
    |> update_progress()
  end

  defp update_tweets(socket) do
    {:ok, paginator} = @search.query(socket.assigns.facets)

    assign(socket, paginator: paginator)
  end

  defp update_top_hashtags(socket) do
    {:ok, top_hashtags} = @search.top_hashtags(socket.assigns.facets)

    assign(socket, top_hashtags: top_hashtags)
  end

  defp update_top_profiles(socket) do
    {:ok, top_profiles} = @search.top_profiles(socket.assigns.facets)

    assign(socket, top_profiles: top_profiles)
  end

  defp update_progress(socket) do
    assign(socket, retrieval: retrieval_info(socket))
  end

  defp retrieval_info(%{assigns: %{remaining_tweets: []}}), do: %Retrieval{}

  defp retrieval_info(socket) do
    {:ok, total_count} = @search.total_count()

    %Retrieval{
      jobs: [
        %Retrieval.Job{
          channel: "Twitter Favorites",
          current: total_count,
          max: total_count + length(socket.assigns.remaining_tweets)
        }
      ]
    }
  end

  defp update_autocomplete(socket, query) do
    {:ok, suggestions} = @search.autocomplete(query)

    assign(socket, autocomplete: suggestions)
  end
end
