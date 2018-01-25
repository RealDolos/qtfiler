defmodule QtfileWeb.RoomController do
  use QtfileWeb, :controller

  def index(conn, %{"room_id" => room_id}) do
    if Qtfile.Rooms.room_exists?(room_id) do
      conn
      |> assign(:room_id, room_id)
      |> render "room.html"
    else
      text conn, "FAILED TO FUIND ROM FUCK OF"
    end
  end

  def create_room(conn, _params) do
    user = Qtfile.Accounts.get_user!(get_session(conn, :user_id))
    room_id = Qtfile.Rooms.generate_room_id()

    Qtfile.Rooms.create_room(room_id, user)

    redirect(conn, to: room_path(conn, :index, room_id))
  end

  def not_found(conn, params) do
    IO.inspect params
    text conn, "fuck off"
  end
end
