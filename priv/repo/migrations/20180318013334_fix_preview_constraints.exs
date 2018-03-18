defmodule Qtfile.Repo.Migrations.FixPreviewConstraints do
  use Ecto.Migration

  def change do
    drop index(:previews, [:file_id, :mime_type])
    create unique_index(:previews, [:file_id, :type, :mime_type])
  end
end
