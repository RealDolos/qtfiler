defmodule QtfileWeb.RoomsView do
  use QtfileWeb, :view

  def print_all_rooms do
    rooms = Qtfile.Rooms.list_rooms()

    for %{room_id: room_id, room_name: room_name, owner: owner} <- rooms do
      render(__MODULE__, "room_line.html", room_id: room_id, room_name: room_name, room_owner: owner)
    end
  end
end
