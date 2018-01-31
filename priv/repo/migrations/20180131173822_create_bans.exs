defmodule Qtfile.Repo.Migrations.CreateBans do
  use Ecto.Migration

  def change do
    create table(:bans) do

      timestamps()
    end

  end
end
