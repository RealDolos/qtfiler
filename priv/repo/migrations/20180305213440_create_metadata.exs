defmodule Qtfile.Repo.Migrations.CreateMetadata do
  use Ecto.Migration

  def change do
    create table(:metadata) do
      add :file_id, references(:files)
      add :data, :map

      timestamps()
    end

    create unique_index(:metadata, [:file_id])
  end
end
