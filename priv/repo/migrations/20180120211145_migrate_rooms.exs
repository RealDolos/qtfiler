defmodule Qtfile.Repo.Migrations.MigrateRooms do
  use Ecto.Migration
  import Ecto.Query

  def change do
    query =
      from u in Qtfile.Rooms.Room
    rooms = Qtfile.Repo.all(query)
    Enum.map(rooms, fn(room) ->
      secret = :crypto.strong_rand_bytes(16)
      changeset = Qtfile.Rooms.Room.changeset(room, %{secret: secret})
      Qtfile.Repo.update!(changeset)
    end)
  end
end
