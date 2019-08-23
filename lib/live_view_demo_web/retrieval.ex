defmodule LiveViewDemoWeb.Retrieval do
  @moduledoc "Data structure for info about ongoing retrieval jobs."

  defstruct jobs: []

  defmodule Job do
    @moduledoc "Retrieval info for one particular retrieval job."

    defstruct [:channel, :current, :max]
  end
end
