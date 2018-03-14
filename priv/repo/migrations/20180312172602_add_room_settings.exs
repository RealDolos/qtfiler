defmodule Qtfile.Repo.Migrations.AddRoomSettings do
  use Ecto.Migration
  alias Qtfile.Repo
  import Qtfile.Rooms

  def change do
    new_settings = [
      %{
        key: "anon_upload",
        value: "false",
        type: "bool",
        name: "Anonymous upload",
      },
      %{
        key: "anon_download",
        value: "false",
        type: "bool",
        name: "Anonymous download",
      },
      %{
        key: "anon_view",
        value: "false",
        type: "bool",
        name: "Anonymous viewing",
      },
    ]
    rooms = list_rooms()
    Enum.map(rooms, fn(room) ->
      room = Repo.preload(room, :settings)
      {:ok, cs} = update_room(room, %{settings: room.settings ++ new_settings})
      cs
    end)
  end
end
