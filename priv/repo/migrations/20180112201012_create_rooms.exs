defmodule Qtfile.Repo.Migrations.CreateRooms do
  use Ecto.Migration

  def change do
    create table(:rooms) do
      add :room_id, :string
      add :room_name, :string
      add :owner, :string
      add :files, {:array, :map}
      add :motd, :string
      add :disabled, :boolean, default: false, null: false
      add :file_ttl, :integer

      timestamps()
    end

    create unique_index(:rooms, [:room_id])
  end
end
