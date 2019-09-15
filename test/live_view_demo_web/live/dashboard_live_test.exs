defmodule LiveViewDemoWeb.DashboardLiveTest do
  use LiveViewDemoWeb.LiveIntegrationCase, async: false

  defp tweets(index_or_range) do
    [File.cwd!(), "priv", "fixtures", "favourites.json"]
    |> Path.join()
    |> File.read!()
    |> Jason.decode!()
    |> Util.Enum.slice(index_or_range)
    |> Util.Map.deep_atomize_keys()
  end

  test "disconnected and connected mount", %{conn: conn} do
    conn = get(conn, "/dashboard")
    assert html_response(conn, 200) =~ "Hammoc"

    {:ok, _view, _html} = live(conn)
  end

  test "shows retrieved Tweets", %{conn: conn, client: client} do
    {:ok, view, _html} = live(conn, "/dashboard")

    retrieval_job = init_retrieval(client, 2)
    refute render(view) =~ "If you lead development teams, you need to read this"
    refute render(view) =~ "How we deal with behaviours and boilerplate"

    retrieval_job = next_retrieval(client, retrieval_job, tweets(0))
    assert render(view) =~ "If you lead development teams, you need to read this"
    refute render(view) =~ "How we deal with behaviours and boilerplate"

    retrieval_job = next_retrieval(client, retrieval_job, tweets(1))
    assert render(view) =~ "If you lead development teams, you need to read this"
    assert render(view) =~ "How we deal with behaviours and boilerplate"

    :ok = finish_retrieval(client, retrieval_job)
    assert render(view) =~ "If you lead development teams, you need to read this"
    assert render(view) =~ "How we deal with behaviours and boilerplate"
  end
end
