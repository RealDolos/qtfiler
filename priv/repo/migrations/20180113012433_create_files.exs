defmodule Qtfile.Repo.Migrations.CreateFiles do
  use Ecto.Migration

  def change do
    create table(:files) do
      add :uuid, :string
      add :filename, :string
      add :extension, :string
      add :room_id, :string
      add :hash, :string
      add :size, :integer
      add :uploader, :string
      add :ip_address, :string
      add :file_ttl, :integer

      timestamps()
    end

    create unique_index(:files, [:uuid])
  end
end
