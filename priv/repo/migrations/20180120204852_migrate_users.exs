defmodule Qtfile.Repo.Migrations.MigrateUsers do
  use Ecto.Migration
  import Ecto.Query

  def change do
    query =
      from u in Qtfile.Accounts.User
    users = Qtfile.Repo.all(query)
    Enum.map(users, fn(user) ->
      secret = :crypto.strong_rand_bytes(16)
      changeset = Qtfile.Accounts.User.changeset(user, %{secret: secret})
      Qtfile.Repo.update!(changeset)
    end)
  end
end
