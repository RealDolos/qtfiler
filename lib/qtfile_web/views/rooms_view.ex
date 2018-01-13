defmodule QtfileWeb.RoomsView do
  use QtfileWeb, :view

  def print_all_rooms do
    rooms = Qtfile.Rooms.list_rooms()

    for %{room_id: room_id, room_name: room_name, files: files, owner: owner} <- rooms do
      render(__MODULE__, "room_line.html", room_id: room_id, room_name: room_name, file_count: files |> Enum.count(), room_owner: owner)
    end
  end
end
