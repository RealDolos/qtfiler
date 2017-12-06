defmodule Qtfile.Repo.Migrations.CreateUsers do
  use Ecto.Migration

  def change do
    create table(:users) do
      add :name, :string
      add :username, :string
      add :password, :string
      add :status, :string, default: "active"
      add :role, :string, default: "user"

      timestamps()
    end

    create unique_index(:users, [:username])
  end
end
