defmodule LiveViewDemo.Retriever.Client do
  @moduledoc "Defines callbacks for a Twitter client module."

  alias LiveViewDemo.Retriever.Status.Job

  @callback init() :: {:ok, Job.t()} | {:error, any()}
  @callback next_batch(Job.t()) :: {:ok, list(any()), Job.t()} | {:error, any()}
end
