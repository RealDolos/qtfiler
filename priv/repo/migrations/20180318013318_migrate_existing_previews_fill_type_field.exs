defmodule Qtfile.Repo.Migrations.MigrateExistingPreviewsFillTypeField do
  use Ecto.Migration
  import Ecto.Query

  def change do
    query =
      from p in Qtfile.Files.Preview
    previews = Qtfile.Repo.all(query)
    Enum.map(previews, fn(preview) ->
      type =
        case preview.mime_type do
          "image/jpeg" -> "image_thumbnail"
          "video/mp4" -> "video_thumbnail"
          "video/webm" -> "video_thumbnail"
        end
      changeset = Ecto.Changeset.cast(preview, %{type: type}, [:type])
      Qtfile.Repo.update!(changeset)
    end)
  end
end
