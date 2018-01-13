defmodule Qtfile.Repo.Migrations.CreateFiles do
  use Ecto.Migration

  def change do
    create table(:files) do
      add :uuid, :string
      add :filename, :string
      add :room_id, :string
      add :hash, :binary

      timestamps()
    end

    create unique_index(:files, [:uuid])
  end
end
