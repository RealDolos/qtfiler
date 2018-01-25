defmodule Qtfile.Repo.Migrations.BinaryIp do
  use Ecto.Migration
  import Ecto.Query

  def change do
    Qtfile.Repo.delete_all(from f in Qtfile.Files.File)

    alter table(:files) do
      remove :ip_address
      add :ip_address, :binary, null: false
    end
  end
end
