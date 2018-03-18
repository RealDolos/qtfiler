defmodule Qtfile.FileProcessing.Thumbnailer do
  use GenStage
  alias Qtfile.FileProcessing.MediaTagger
  require Logger

  def start_link(args) do
    GenStage.start_link(__MODULE__, args, name: __MODULE__)
  end

  def init([]) do
    {:producer_consumer, {},
     dispatcher: GenStage.BroadcastDispatcher,
     subscribe_to: [{MediaTagger, selector: &tag_selector/1}],
    }
  end

  defp tag_selector({:media, :image, %{mime_type: "image/gif"}}) do
    false
  end

  defp tag_selector({:media, :image, %{mime_type: "image/apng"}}) do
    false
  end

  defp tag_selector({:media, :image, _}) do
    true
  end

  defp tag_selector(_) do
    false
  end

  def handle_events(tagged_files, _from, {}) do
    thumbnails = Enum.flat_map(tagged_files, fn({:media, :image, file}) ->
      try do
        [thumbnail(file)]
      rescue
        e ->
          Logger.info "thumbgen error"
          Logger.info(inspect(e))
          []
      end
    end)

    {:noreply, thumbnails, {}}
  end

  defp preview_type do
    "image_thumbnail"
  end

  defp thumbnail(file) do
    path = "uploads/" <> file.uuid
    output_path = "previews/" <> file.uuid <> "^" <> preview_type
    output_path_ext = output_path <> ".jpg"

    result = Porcelain.exec("vipsthumbnail",
      [
        path,
        "--size", Integer.to_string(Qtfile.Settings.get_setting_value!("thumbsize")),
        "--linear", "--rotate", "-o",
        output_path_ext <> "[optimize_coding,interlace,strip]",
      ]
    )

    0 = result.status
    :ok = :file.rename("uploads/" <> output_path_ext, "uploads/" <> output_path)

    {:ok, thumbnail} = Qtfile.Files.add_preview(
      %{
        file: file,
        mime_type: "image/jpeg",
        type: preview_type,
      }
    )
    thumbnail
  end
end
