defmodule Qtfile.Repo.Migrations.CreateSettings do
  use Ecto.Migration

  def change do
    create table(:settings) do
      add :name, :string
      add :key, :string
      add :value, :string
      add :type, :string

      timestamps()
    end
  end
end
