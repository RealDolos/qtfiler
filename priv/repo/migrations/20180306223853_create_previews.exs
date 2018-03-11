defmodule Qtfile.Repo.Migrations.CreatePreviews do
  use Ecto.Migration

  def change do
    create table(:previews) do
      add :file_id, references(:files)
      add :mime_type, :string

      timestamps()
    end

    create unique_index(:previews, [:file_id, :mime_type])
  end
end
