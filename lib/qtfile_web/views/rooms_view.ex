defmodule QtfileWeb.RoomsView do
  use QtfileWeb, :view

  def print_all_rooms(logged_in) do
    rooms =
      case logged_in do
        true -> Qtfile.Rooms.list_rooms()
        false -> Qtfile.Rooms.list_rooms_anon()
      end

    for %{room_id: room_id, room_name: room_name, owner: owner} <- rooms do
      render(__MODULE__, "room_line.html", room_id: room_id, room_name: room_name, room_owner: owner.name)
    end
  end
end
