defmodule Qtfile.Repo.Migrations.AddSecretToRoom do
  use Ecto.Migration

  def change do
    alter table(:rooms) do
      add :secret, :binary
    end

    create unique_index(:rooms, [:secret])
  end
end
