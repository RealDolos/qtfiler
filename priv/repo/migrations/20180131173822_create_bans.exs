defmodule Qtfile.Repo.Migrations.CreateBans do
  use Ecto.Migration

  def change do
    create table(:bans) do
      add :banner_id, references(:users)
      add :room_id, references(:rooms)
      add :end, :utc_datetime
      add :reason, :string

      timestamps()
    end
    create index(:bans, [:end, :banner_id, :room_id])
    create index(:bans, [:end, :room_id])
    create index(:bans, [:banner_id, :room_id])
    create index(:bans, [:room_id])

    create table(:file_bans) do
      add :ban_id, references(:bans)
      add :hash, :string

      timestamps()
    end
    create unique_index(:file_bans, [:ban_id, :hash])
    create index(:file_bans, [:hash])

    create table(:user_bans) do
      add :ban_id, references(:bans)
      add :bannee_id, references(:users)
      add :hell, :boolean

      timestamps()
    end
    create unique_index(:user_bans, [:ban_id, :bannee_id])
    create index(:user_bans, [:bannee_id])

    create table(:ip_bans) do
      add :user_ban_id, references(:user_bans)
      add :ip_address, :binary

      timestamps()
    end
    create unique_index(:ip_bans, [:user_ban_id, :ip_address])
    create index(:ip_bans, [:ip_address])    
  end
end
