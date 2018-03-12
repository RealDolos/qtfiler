defmodule Qtfile.Repo.Migrations.AnonViewGlobalSettings do
  use Ecto.Migration
  import Qtfile.Settings

  def change do
    {:ok, _} = create_setting(
      %{
        name: "Anonymous room viewing",
        key: "anon_view",
        value: "false",
        type: "bool",
      }
    )
  end
end
