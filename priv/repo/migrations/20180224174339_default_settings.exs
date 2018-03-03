defmodule Qtfile.Repo.Migrations.DefaultSettings do
  use Ecto.Migration
  import Qtfile.Settings

  def change do
    {:ok, _} = create_setting(
      %{
        name: "Anonymous downloading",
        key: "anon_download",
        value: "false",
        type: "bool",
      }
    )
    {:ok, _} = create_setting(
      %{
        name: "Anonymous uploading",
        key: "anon_upload",
        value: "false",
        type: "bool",
      }
    )
    {:ok, _} = create_setting(
      %{
        name: "Maximum file size",
        key: "max_file_length",
        value: "4294967296",
        type: "int",
      }
    )
  end
end
