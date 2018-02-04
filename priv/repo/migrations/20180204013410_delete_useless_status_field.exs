defmodule Qtfile.Repo.Migrations.DeleteUselessStatusField do
  use Ecto.Migration

  def change do
    alter table(:users) do
      remove :status
    end
  end
end
