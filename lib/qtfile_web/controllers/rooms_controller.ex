defmodule QtfileWeb.RoomsController do
  use QtfileWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html")
  end
end
