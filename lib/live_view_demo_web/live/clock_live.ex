defmodule LiveViewDemoWeb.ClockLive do
  @moduledoc "Initial LiveView example"

  use Phoenix.LiveView
  import Calendar.Strftime

  def render(assigns) do
    ~L"""
    <a class="button" phx-click="boom">
      It's <%= strftime!(@date, "%r") %>
    </a>
    """
  end

  def mount(_session, socket) do
    if connected?(socket), do: :timer.send_interval(1000, self(), :tick)

    {:ok, put_date(socket)}
  end

  def handle_info(:tick, socket) do
    {:noreply, put_date(socket)}
  end

  defp put_date(socket) do
    assign(socket, date: :calendar.local_time())
  end
end
