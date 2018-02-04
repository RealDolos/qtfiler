defmodule Qtfile.Repo.Migrations.Indexes do
  use Ecto.Migration

  def change do
    create index(:rooms, [:owner_id])
    create index(:rooms, [:disabled])
    create index(:files, [:hash])
    create index(:files, [:ip_address])
    create index(:users, [:role])
  end
end
