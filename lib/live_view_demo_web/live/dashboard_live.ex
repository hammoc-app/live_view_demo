defmodule LiveViewDemoWeb.DashboardLive do
  @moduledoc "A dashboard for your likes and bookmarks powered LiveView"

  use Phoenix.LiveView

  alias LiveViewDemoWeb.Router.Helpers, as: Routes

  def render(assigns) do
    Phoenix.View.render(LiveViewDemoWeb.PageView, "dashboard.html",
      user: assigns.user,
      results: assigns.tweets,
      top_hashtags: assigns.top_hashtags,
      top_profiles: assigns.top_profiles,
      filters: assigns.filters,
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

    filters = %{
      hashtags: nil,
      profiles: nil
    }

    new_socket =
      socket
      |> assign(:user, user)
      |> assign(:tweets, [])
      |> assign(:top_hashtags, [])
      |> assign(:top_profiles, [])
      |> assign(:loaded_tweets, [])
      |> assign(:remaining_tweets, remaining_tweets)
      |> assign(:filters, filters)

    {:ok, new_socket}
  end

  def handle_params(params, _uri, socket) do
    new_socket = assign(socket, :filters, decode_params(params))

    {:noreply, new_socket}
  end

  defp decode_params(params) do
    IO.inspect(params, label: "decoding")

    %{
      hashtags: list_param(params["hashtags"]),
      profiles: list_param(params["profiles"])
    }
    |> IO.inspect(label: "decoded")
  end

  defp list_param(nil), do: nil

  defp list_param(str) when is_binary(str) do
    String.split(str, ",")
  end

  def handle_event("filters-changed", params, socket) do
    new_socket =
      live_redirect(socket, to: Routes.live_path(socket, __MODULE__, encode_params(params)))

    {:noreply, new_socket}
  end

  defp encode_params(params) do
    params
    |> IO.inspect(label: "encoding")
    |> encode_list("hashtags")
    |> encode_list("profiles")
    |> IO.inspect(label: "encoded")
  end

  defp encode_list(params, field) do
    case params[field] do
      nil -> params
      list -> Map.put(params, field, do_encode_list(list))
    end
  end

  defp do_encode_list(list) do
    items = for {item, "true"} <- list, do: item
    Enum.join(items, ",")
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
      |> filter_by(filters.hashtags, fn tweet ->
        Enum.map(tweet.entities.hashtags, & &1.text)
      end)
      |> filter_by(filters.profiles, & &1.user.screen_name)

    assign(socket, tweets: tweets)
  end

  defp filter_by(results, nil, _mapper), do: results

  defp filter_by(results, filter, mapper) do
    Enum.filter(results, fn result ->
      result
      |> mapper.()
      |> include_result?(filter)
    end)
  end

  defp include_result?(result_list, inclusion_list)
       when is_list(result_list) and is_list(inclusion_list) do
    Enum.any?(result_list, &(&1 in inclusion_list))
  end

  defp include_result?(result, inclusion_list) when is_list(inclusion_list) do
    result in inclusion_list
  end

  defp update_top_hashtags(socket) do
    top_hashtags =
      socket.assigns.loaded_tweets
      |> Enum.flat_map(& &1.entities.hashtags)
      |> Enum.map(& &1.text)
      |> Enum.uniq()
      |> Enum.sort()
      |> Enum.take(5)

    assign(socket, top_hashtags: top_hashtags)
  end

  defp update_top_profiles(socket) do
    top_profiles =
      socket.assigns.loaded_tweets
      |> Enum.map(& &1.user)
      |> Enum.uniq_by(& &1.screen_name)
      |> Enum.sort_by(& &1.followers_count)
      |> Enum.take(5)

    assign(socket, top_profiles: top_profiles)
  end
end
