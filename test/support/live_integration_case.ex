defmodule LiveViewDemoWeb.LiveIntegrationCase do
  @moduledoc """
  This module defines the test case to be used by
  tests for everything between API responses and
  rendered LiveViews.

  Such tests rely on `Phoenix.ConnTest` and also
  import other functionality to make it easier
  to build common data structures and query the data layer.

  Finally, if the test case interacts with the database,
  it cannot be async. For this reason, every test runs
  inside a transaction which is reset at the beginning
  of the test unless the test case is marked as async.
  """

  use ExUnit.CaseTemplate

  using do
    quote do
      # Import conveniences for testing with connections
      use Phoenix.ConnTest
      alias LiveViewDemoWeb.Router.Helpers, as: Routes

      alias LiveViewDemo.Retriever.Status.Job

      # The default endpoint for testing
      @endpoint LiveViewDemoWeb.Endpoint

      @client Application.get_env(:live_view_demo, LiveViewDemo.Retriever)[:client_module]

      alias Phoenix.LiveViewTest
      require LiveViewTest

      use PhoenixLiveViewIntegration
      alias PhoenixLiveViewIntegration.State

      def init_retrieval(state = %State{}, total_count) do
        retrieval_job = %Job{channel: "Twitter Favorites", current: 0, max: total_count}
        {:ok, :init} = @client.send_reply({:ok, retrieval_job})

        %{state | extra: %{retrieval_job: retrieval_job}, html: wait_for_html(state)}
      end

      def next_retrieval(state = %State{extra: %{retrieval_job: retrieval_job}}, batch) do
        new_retrieval_job = Map.update(retrieval_job, :current, 0, &(&1 + length(batch)))
        {:ok, {:next_batch, ^retrieval_job}} = @client.send_reply({:ok, batch, new_retrieval_job})

        %{state | extra: %{retrieval_job: new_retrieval_job}, html: wait_for_html(state)}
      end

      def finish_retrieval(state = %State{extra: %{retrieval_job: retrieval_job}}) do
        new_retrieval_job = Map.put(retrieval_job, :current, retrieval_job.max)
        {:ok, {:next_batch, ^retrieval_job}} = @client.send_reply({:ok, [], new_retrieval_job})

        %{state | extra: %{retrieval_job: nil}, html: wait_for_html(state)}
      end

      defp wait_for_html(state) do
        :timer.sleep(100)
        LiveViewTest.render(state.view)
      end
    end
  end

  setup tags do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(LiveViewDemo.Repo)

    unless tags[:async] do
      Ecto.Adapters.SQL.Sandbox.mode(LiveViewDemo.Repo, {:shared, self()})
    end

    {:ok, conn: Phoenix.ConnTest.build_conn()}
  end
end
