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

  defp thumbnail(file) do
    path = "uploads/" <> file.uuid
    output_path = "previews/" <> file.uuid <> ".jpg"

    result = Porcelain.exec("vipsthumbnail",
      [
        path,
        "--size", Integer.to_string(Qtfile.Settings.get_setting_value!("thumbsize")),
        "--linear", "--rotate", "-o",
        output_path <> "[optimize_coding,interlace,strip]",
      ]
    )

    0 = result.status
    {:ok, thumbnail} = Qtfile.Files.add_preview(
      %{
        file: file,
        mime_type: "image/jpeg",
        type: "image_thumbnail",
      }
    )
    thumbnail
  end
end
