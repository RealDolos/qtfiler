defmodule Qtfile.FileProcessing.MetadataGenerator do
  use GenStage
  alias Qtfile.FileProcessing.MediaTagger

  def start_link(args) do
    GenStage.start_link(__MODULE__, args, name: __MODULE__)
  end

  def init([]) do
    {:producer_consumer, {},
     dispatcher: GenStage.BroadcastDispatcher,
     subscribe_to: [{MediaTagger, selector: &tag_selector/1}],
    }
  end

  defp tag_selector({:media, _, _}) do
    true
  end

  defp tag_selector(_) do
    false
  end

  def handle_events(tagged_files, _from, {}) do
    metadata_objects = Enum.map(tagged_files, fn({:media, type, file}) ->
      {:media, type, process_media_file(file)}
    end)

    {:noreply, metadata_objects, {}}
  end

  defp process_media_file(file) do
    path = "uploads/" <> file.uuid

    result = Porcelain.exec("ffprobe",
      ["-print_format", "json", "-show_format", "-show_streams", path]
    )

    0 = result.status
    result = Poison.decode!(result.out)
    {:ok, metadata_object} = Qtfile.Files.add_metadata(file, result)
    metadata_object
  end
end
