defmodule Qtfile.Repo.Migrations.AddSecretToUser do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :secret, :binary
    end

    create unique_index(:users, [:secret])
  end
end
