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
    metadata_objects = Enum.flat_map(tagged_files, fn({:media, type, file}) ->
      try do
        [{:media, type, process_media_file(file, type)}]
      rescue
        _ -> []
      end
    end)

    {:noreply, metadata_objects, {}}
  end

  defp process_media_file(file, type) do
    path = "uploads/" <> file.uuid

    show_data_args = Enum.map(
      case type do
        :image -> ["show_format", "show_streams", "show_frames"]
        _ -> ["show_format", "show_streams"]
      end,
      fn (arg) ->
        "-" <> arg
      end
    )

    result = Porcelain.exec("ffprobe",
      ["-print_format", "json"] ++ show_data_args ++ [path]
    )

    0 = result.status
    result = Poison.decode!(result.out)
    {:ok, metadata_object} = Qtfile.Files.add_metadata(file, result)
    metadata_object
  end
end
