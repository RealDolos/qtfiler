defmodule Qtfile.Repo.Migrations.ForeignOwner do
  use Ecto.Migration
  import Ecto.Query

  def change do
    alter table(:rooms) do
      remove :owner
      add :owner, references(:users)
    end
  end
end
