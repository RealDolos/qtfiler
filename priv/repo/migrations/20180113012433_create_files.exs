defmodule Qtfile.Repo.Migrations.CreateFiles do
  use Ecto.Migration

  def change do
    create table(:files) do
      add :uuid, :string
      add :filename, :string
      add :mime_type, :string
      add :rooms_id, references(:rooms)
      add :hash, :string
      add :size, :integer
      add :users_id, references(:users)
      add :ip_address, :string
      add :expiration_date, :utc_datetime

      timestamps()
    end

    create unique_index(:files, [:uuid])
    create index(:files, [:expiration_date])
    create index(:files, [:users_id])
    create index(:files, [:rooms_id])
  end
end
