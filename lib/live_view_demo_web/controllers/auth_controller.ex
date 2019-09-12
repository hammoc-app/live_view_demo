defmodule LiveViewDemoWeb.AuthController do
  use LiveViewDemoWeb, :controller

  def twitter(conn, _params) do
    redirect(conn, to: Routes.live_path(conn, LiveViewDemoWeb.DashboardLive))
  end
end
