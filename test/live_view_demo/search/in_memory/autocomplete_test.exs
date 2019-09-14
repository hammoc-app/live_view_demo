defmodule LiveViewDemo.Search.InMemory.AutocompleteTest do
  use ExUnit.Case, async: true

  alias LiveViewDemo.Search.InMemory.Autocomplete

  setup do
    {:ok,
     entries: [
       %{text: "We love testing"},
       %{text: "Tests are my favorite way of testing!"},
       %{text: "If I couldn't test my code, oh my, some people would run out of Testosterone"}
     ]}
  end

  test "Empty list" do
    assert Autocomplete.for([], & &1, "test") == []
  end

  test "All results", %{entries: entries} do
    results =
      entries
      |> Autocomplete.for(& &1.text, "test")
      |> Enum.sort()

    assert results == Enum.sort(["testing", "tests", "test", "testosterone"])
  end

  test "Result limit", %{entries: entries} do
    results =
      entries
      |> Autocomplete.for(& &1.text, "test", 2)
      |> Enum.sort()

    assert results == Enum.sort(["testing", "tests"])
  end
end
