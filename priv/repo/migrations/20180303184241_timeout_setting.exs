defmodule Qtfile.Repo.Migrations.TimeoutSetting do
  use Ecto.Migration
  import Qtfile.Settings

  def change do
    {:ok, _} = create_setting(
      %{
        name: "Upload timeout",
        key: "upload_timeout",
        value: "1024",
        type: "int",
      }
    )
  end
end
