defmodule LiveViewDemoWeb.Filters do
  @moduledoc "Data structure and helpers to deal with the filters form."

  defstruct [:hashtags, :profiles, :query]

  @doc """
  Transforms form params so they can be given as (URL) path options.

  ## Examples

      iex> %{"hashtags" => %{"elixirlang" => "true"}, "q" => "testing"}
      ...> |> LiveViewDemoWeb.Filters.encode_params()
      %{"hashtags" => "elixirlang", "q" => "testing"}

      iex> %{"hashtags" => %{"elixirlang" => "true", "liveview" => "true"}, "q" => ""}
      ...> |> LiveViewDemoWeb.Filters.encode_params()
      %{"hashtags" => "elixirlang,liveview"}
  """
  def encode_params(params) do
    params
    |> encode_list("hashtags")
    |> encode_list("profiles")
    |> encode_text("q")
  end

  defp encode_text(params, field) do
    case params[field] do
      "" -> params |> Map.delete(field)
      _ -> params
    end
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

  @doc """
  Parses filters from URL query params.

  ## Examples

      iex> %{"hashtags" => "elixirlang", "q" => "testing"}
      ...> |> LiveViewDemoWeb.Filters.decode_params()
      %LiveViewDemoWeb.Filters{hashtags: ["elixirlang"], query: "testing"}

      iex> %{"hashtags" => "elixirlang,liveview", "q" => ""}
      ...> |> LiveViewDemoWeb.Filters.decode_params()
      %LiveViewDemoWeb.Filters{hashtags: ["elixirlang", "liveview"]}
  """
  def decode_params(params) do
    %__MODULE__{
      hashtags: list_param(params["hashtags"]),
      profiles: list_param(params["profiles"]),
      query: text_param(params["q"])
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

  defp include_result?(result, text) when is_binary(text) do
    String.contains?(result, text)
  end
end
