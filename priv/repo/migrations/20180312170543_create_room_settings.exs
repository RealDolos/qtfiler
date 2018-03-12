defmodule Qtfile.Repo.Migrations.CreateRoomSettings do
  use Ecto.Migration

  def change do
    create table(:room_settings) do
      add :name, :string
      add :key, :string
      add :value, :string
      add :type, :string
      add :room_id, references(:rooms, on_delete: :delete_all, on_update: :update_all)

      timestamps()
    end
  end
end
