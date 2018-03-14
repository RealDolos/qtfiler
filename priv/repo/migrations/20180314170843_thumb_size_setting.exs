defmodule Qtfile.Repo.Migrations.ThumbSizeSetting do
  use Ecto.Migration
  import Qtfile.Settings

  def change do
    {:ok, _} = create_setting(
      %{
        name: "Thumbnail size",
        key: "thumbsize",
        value: "256",
        type: "int",
      }
    )
  end
end
