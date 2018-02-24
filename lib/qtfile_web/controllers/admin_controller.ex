defmodule QtfileWeb.AdminController do
  use QtfileWeb, :controller

  def settings(conn, _params) do
    render(conn, "settings.html")
  end
end
