defmodule QtfileWeb.RoomController do
  use QtfileWeb, :controller
  require Logger

  def index(conn, %{"room_id" => room_id}) do
    case Qtfile.Rooms.get_room_by_room_id!(room_id) do
      nil -> text conn, "FAILED TO FIND ROM FUCK OF"
      room ->
        logged_in = not is_nil(get_session(conn, :user_id))
        allowed = logged_in or Qtfile.Rooms.get_setting_value!("anon_view", room)
        if allowed do
          conn
          |> assign(:room_id, room_id)
          |> render "room.html"
        else
          conn
          |> send_resp(:forbidden, "Not logged in")
          |> halt()
        end
    end
  end

  def create_room(conn, _params) do
    user = Qtfile.Accounts.get_user!(get_session(conn, :user_id))
    room_id = Qtfile.Rooms.generate_room_id()

    case Qtfile.Rooms.create_room(room_id, user) do
      {:ok, _} -> redirect(conn, to: room_path(conn, :index, room_id))
      {:error, e} ->
        Logger.error("failed to create room:")
        Logger.error(inspect(e))
        redirect(conn, to: "/")
    end
  end

  def not_found(conn, params) do
    IO.inspect params
    text conn, "fuck off"
  end
end
