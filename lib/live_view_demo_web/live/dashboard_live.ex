defmodule LiveViewDemoWeb.DashboardLive do
  @moduledoc "A dashboard for your likes and bookmarks powered LiveView"

  use Phoenix.LiveView

  alias LiveViewDemoWeb.Router.Helpers, as: Routes
  alias LiveViewDemoWeb.Filters

  def render(assigns) do
    Phoenix.View.render(LiveViewDemoWeb.PageView, "dashboard.html",
      user: assigns.user,
      results: assigns.tweets,
      top_hashtags: assigns.top_hashtags,
      top_profiles: assigns.top_profiles,
      filters: assigns.filters,
      autocomplete: assigns.autocomplete,
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
      |> assign(:filters, %Filters{})
      |> assign(:autocomplete, nil)

    {:ok, new_socket}
  end

  def handle_params(params, _uri, socket) do
    new_socket = assign(socket, :filters, Filters.decode_params(params))

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

  defp search(socket, params, autocomplete) do
    filter_params = Filters.encode_params(params)
    path = Routes.live_path(socket, __MODULE__, filter_params)

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
    socket
    |> update(:loaded_tweets, fn loaded_tweets -> loaded_tweets ++ tweets end)
    |> update_tweets()
    |> update_top_hashtags()
    |> update_top_profiles()
  end

  defp update_tweets(socket) do
    filters = socket.assigns.filters

    tweets =
      socket.assigns.loaded_tweets
      |> Filters.filter_by(filters.hashtags, fn tweet ->
        Enum.map(tweet.entities.hashtags, & &1.text)
      end)
      |> Filters.filter_by(filters.profiles, & &1.user.screen_name)
      |> Filters.filter_by(filters.query, & &1.text)

    assign(socket, tweets: tweets)
  end

  defp update_top_hashtags(socket) do
    based_on =
      if socket.assigns.filters.hashtags do
        socket.assigns.loaded_tweets
      else
        socket.assigns.tweets
      end

    top_hashtags =
      based_on
      |> Enum.flat_map(& &1.entities.hashtags)
      |> ranked_options(socket.assigns.filters.hashtags, & &1.text)

    assign(socket, top_hashtags: top_hashtags)
  end

  defp update_top_profiles(socket) do
    based_on =
      if socket.assigns.filters.profiles do
        socket.assigns.loaded_tweets
      else
        socket.assigns.tweets
      end

    top_profiles =
      based_on
      |> ranked_options(socket.assigns.filters.profiles, & &1.user.screen_name)
      |> Enum.map(fn screen_name ->
        Enum.find_value(socket.assigns.loaded_tweets, fn tweet ->
          if tweet.user.screen_name == screen_name, do: tweet.user
        end)
      end)

    assign(socket, top_profiles: top_profiles)
  end

  defp ranked_options(options, selected_options, mapper) do
    options
    |> Util.Enum.count(mapper)
    |> Util.Enum.top_counts(5)
    |> Enum.map(&elem(&1, 0))
    |> prepend_options(selected_options)
    |> Enum.uniq()
    |> Enum.take(5)
  end

  defp prepend_options(options, prepend, mapper \\ nil)

  defp prepend_options(options, nil, _mapper), do: options
  defp prepend_options(options, prepend, nil), do: prepend ++ options

  defp prepend_options(options, prepend, mapper) do
    prepend_options(options, Enum.map(prepend, mapper))
  end

  defp update_autocomplete(socket, query) do
    words =
      case query do
        nil ->
          nil

        query ->
          if String.length(query) >= 3 do
            add_autocomplete_from(query, socket.assigns.loaded_tweets, [], MapSet.new())
          end
      end

    assign(socket, autocomplete: words)
  end

  defp add_autocomplete_from(_query, [], [], results), do: results

  defp add_autocomplete_from(query, [tweet | tweets], [], results) do
    words = ~r/[\w\-\_]+/i
    |> Regex.scan(String.downcase(tweet.text))
    |> List.flatten()

    add_autocomplete_from(query, tweets, words, results)
  end

  defp add_autocomplete_from(query, tweets, [word | words], results) do
    if String.starts_with?(word, query) do
      if MapSet.member?(results, word) do
        add_autocomplete_from(query, tweets, words, results)
      else
        new_results = MapSet.put(results, word)

        if map_size(new_results) == 5 do
          new_results
        else
          add_autocomplete_from(query, tweets, words, new_results)
        end
      end
    else
      add_autocomplete_from(query, tweets, words, results)
    end
  end
end
