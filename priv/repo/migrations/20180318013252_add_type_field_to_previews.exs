defmodule Qtfile.Repo.Migrations.AddTypeFieldToPreviews do
  use Ecto.Migration

  def change do
    alter table(:previews) do
      add :type, :string
    end
  end
end
