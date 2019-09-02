defmodule LiveViewDemo.Search.Facets do
  @moduledoc "Data structure and helpers to deal with the filters form."

  defstruct [:hashtags, :profiles, :query, page: 1]

  @doc """
  Transforms form params so they can be given as (URL) path options.

  ## Examples

      iex> %{"hashtags" => %{"elixirlang" => "true"}, "q" => "testing"}
      ...> |> LiveViewDemo.Search.Facets.encode_params()
      %{"hashtags" => "elixirlang", "q" => "testing"}

      iex> %{"hashtags" => %{"elixirlang" => "true", "liveview" => "true"}, "q" => ""}
      ...> |> LiveViewDemo.Search.Facets.encode_params()
      %{"hashtags" => "elixirlang,liveview"}

      iex> %LiveViewDemo.Search.Facets{hashtags: ["elixirlang", "liveview"], query: "dev"}
      ...> |> LiveViewDemo.Search.Facets.encode_params()
      %{"hashtags" => "elixirlang,liveview", "q" => "dev"}
  """
  def encode_params(params = %__MODULE__{}) do
    %{
      "hashtags" => params.hashtags,
      "profiles" => params.profiles,
      "q" => params.query,
      "p" => params.page
    }
    |> encode_params()
  end

  def encode_params(params) do
    params
    |> encode_list("hashtags")
    |> encode_list("profiles")
    |> encode_text("q")
    |> encode_text("p", 1)
  end

  defp encode_text(params, field, default \\ "") do
    case params[field] do
      ^default -> Map.delete(params, field)
      nil -> Map.delete(params, field)
      _ -> params
    end
  end

  defp encode_list(params, field) do
    case params[field] do
      nil -> Map.delete(params, field)
      list -> Map.put(params, field, do_encode_list(list))
    end
  end

  defp do_encode_list(list) when is_list(list) do
    Enum.join(list, ",")
  end

  defp do_encode_list(map) when is_map(map) do
    items = for {item, "true"} <- map, do: item
    do_encode_list(items)
  end

  @doc """
  Parses filters from URL query params.

  ## Examples

      iex> %{"hashtags" => "elixirlang", "q" => "testing"}
      ...> |> LiveViewDemo.Search.Facets.decode_params()
      %LiveViewDemo.Search.Facets{hashtags: ["elixirlang"], query: "testing"}

      iex> %{"hashtags" => "elixirlang,liveview", "q" => ""}
      ...> |> LiveViewDemo.Search.Facets.decode_params()
      %LiveViewDemo.Search.Facets{hashtags: ["elixirlang", "liveview"]}

      iex> %{"hashtags" => "elixirlang,liveview", "p" => "3"}
      ...> |> LiveViewDemo.Search.Facets.decode_params()
      %LiveViewDemo.Search.Facets{hashtags: ["elixirlang", "liveview"], page: 3}
  """
  def decode_params(params) do
    %__MODULE__{
      hashtags: list_param(params["hashtags"]),
      profiles: list_param(params["profiles"]),
      query: text_param(params["q"]),
      page: number_param(params["p"], 1)
    }
  end

  defp list_param(nil), do: nil
  defp list_param(""), do: nil

  defp list_param(str) when is_binary(str) do
    String.split(str, ",")
  end

  defp text_param(nil), do: nil
  defp text_param(""), do: nil
  defp text_param(str) when is_binary(str), do: str

  defp number_param(nil, default), do: default
  defp number_param("", default), do: default

  defp number_param(str, default) do
    case String.to_integer(str) do
      n when n > 0 -> n
      _ -> default
    end
  end

  def filter_by(results, nil, _mapper), do: results

  def filter_by(results, filter, mapper) do
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

  defp include_result?(result, query) when is_binary(query) do
    String.match?(result, ~r/#{query}/iu)
  end
end
